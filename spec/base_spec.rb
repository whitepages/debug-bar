require 'spec_helper'

describe DebugBar::Base do

  describe 'callbacks' do

    before(:each) do
      @debug_bar = DebugBar::Base.new
    end

    it 'should register recipes in initializer after the block is called' do
      debug_bar = DebugBar::Base.new(:params) do |bar|
        bar.add_recipe_book(DebugBar::RecipeBook::Default)
        bar.callbacks.length.should == 0
      end

      debug_bar.callbacks.length.should == 1
    end


    it 'should register blocks' do
      @debug_bar.add {|b| ["Test Block", "Test Content", {}]}

      @debug_bar.callbacks.length.should == 1
      @debug_bar.callbacks.first.should be_kind_of(Proc)
    end

    it 'should register recipes' do
      @debug_bar.add_recipe_book(DebugBar::RecipeBook::Default)
      @debug_bar.add(:params)

      @debug_bar.callbacks.length.should == 1
      @debug_bar.callbacks.first.should be_kind_of(Proc)
    end

    it 'should error on nil' do
      lambda {@debug_bar.add(nil)}.should raise_error(ArgumentError)
    end

  end

  describe 'render' do

    before(:each) do
      @debug_bar = DebugBar::Base.new
    end

    it 'should render blocks' do
      title = "Testing The Block"
      content = "<pre>Alpha Beta</pre>"
      @debug_bar.add {|b| [title, content, {}]}

      html = @debug_bar.render(binding)

      html.should be_kind_of(String)
      html.should_not be_empty

      html.index(title).should_not be_nil
      html.index(content).should_not be_nil
    end

    it 'should render as html_safe string' do
      @debug_bar.add {|b| ["foo", "bar", {}]}
      html = @debug_bar.render(binding)
      html.should be_kind_of(ActiveSupport::SafeBuffer)
    end

    it 'should render with a given binding' do
      @debug_bar.add {|b| ["Title", "||#{b.eval('foobar')}||", {}]}

      foobar = "Spoilers!"
      html = @debug_bar.render(binding)

      html.should be_kind_of(String)

      html.index(foobar).should_not be_nil
    end

    it 'should render with a custom decorated binding' do
      @debug_bar.add {|b| ["Binding", "||get is #{b.respond_to?(:[])}||", {}]}

      binding.should_not respond_to(:[])
      html = @debug_bar.render(binding)

      html.index("||get is true||").should_not be_nil
    end

    it 'should render recipes' do
      @debug_bar.add_recipe_book(DebugBar::RecipeBook::Default)
      @debug_bar.add(:params)
      params = {:given_name => 'Amelia', :family_name => 'Pond'}

      html = @debug_bar.render(binding)

      html.should be_kind_of(String)
      html.should_not be_empty

      html.index('Amelia').should_not be_nil
      html.index(':given_name').should_not be_nil
      html.index('dbar-content show').should_not be_nil # See if params was expanded.
    end

    it 'should render recipes with args' do
      @debug_bar.add_recipe_book(DebugBar::RecipeBook::Default)
      @debug_bar.add(:params, :cutoff => 12)

      params = {:given_name => 'Amelia', :family_name => 'Pond'}

      html = @debug_bar.render(binding)

      html.should be_kind_of(String)
      html.should_not be_empty

      html.index('Amelia').should_not be_nil
      html.index(':given_name').should_not be_nil
      html.index('dbar-content show').should be_nil # See if params was collapsed due to cutoff.
    end

    it 'should render the callback_box' do
      @debug_bar.add {|b| ["foo", "bar", {}]}
      html = @debug_bar.render(binding)

      html.index('callback-box').should_not be_nil # Picked the CSS class as a good indicator of presence.
    end

    it 'should render the layout' do
      @debug_bar.add {|b| ["foo", "bar", {}]}
      html = @debug_bar.render(binding)

      html.index('debug-bar').should_not be_nil # Picked the presence of CSS class as a good inidcator of presence.
    end

    it 'should render on crash in callback' do
      @debug_bar.add {|b| raise RuntimeError, "Uh-oh, you didn't handle the exception!"}
      html = ''
      lambda {html = @debug_bar.render(binding)}.should_not raise_error
      puts html.inspect
    end

  end

  describe 'options' do

    before(:each) do
      @debug_bar = DebugBar::Base.new
    end

    it 'should interpret missing opts from callback as {}' do
      @debug_bar.add {|b| ['foo', 'bar']}

      html = @debug_bar.render(binding)

      html.should be_kind_of(String)
      html.should_not be_empty

      html.index('foo').should_not be_nil
      html.index('bar').should_not be_nil
    end

    it 'should interpret nil opts from callback as {}' do
      @debug_bar.add {|b| ['foo', 'bar', nil]}

      html = @debug_bar.render(binding)

      html.should be_kind_of(String)
      html.should_not be_empty

      html.index('foo').should_not be_nil
      html.index('bar').should_not be_nil
    end

    it 'should default :hidden option to true if not explicitly given and session remembers it as open based on id' do
      # Emulate saving of open callback box ids in cookies.
      cookies = {:debug_bar => 'rory_williams,amelia_pond'}
      # Put into binding.
      b = binding

      html_rory = DebugBar::Base.new.add {|b| ['foo', 'bar', :id => 'rory_williams']}.render(b)
      html_rose = DebugBar::Base.new.add {|b| ['foo', 'bar', :id => 'rose_tyler']}.render(b)

      # Extract the classes from the first div that has a dbar-content class in it.
      extract_classes = lambda do |html|
        m = /<div[^>]+class=['"]([^>'"]*dbar-content[^>'"]*)[^>]+>/.match(html)
        return m.to_a[1].to_s.split(/\s+/)
      end

      html_rory.should include('show')
      html_rose.should_not include('show')
    end

    it 'should recognize :hidden options' do
      html_hidden = DebugBar::Base.new.add {|b| ['foo', 'bar', :hidden => true]}.render(binding)
      html_nohide = DebugBar::Base.new.add {|b| ['foo', 'bar', :hidden => false]}.render(binding)

      # Extract the classes from the first div that has a dbar-content class in it.
      extract_classes = lambda do |html|
        m = /<div[^>]+class=['"]([^>'"]*dbar-content[^>'"]*)[^>]+>/.match(html)
        return m.to_a[1].to_s.split(/\s+/)
      end

      extract_classes.call(html_hidden).should_not include('show')
      extract_classes.call(html_nohide).should include('show')
    end

  end

  describe 'recipe books' do

    class TestBook < DebugBar::RecipeBook::Base
      def duplicated_recipe
        Proc.new {|b| :test_book_duplicated_recipe}
      end

      def beta_recipe
        Proc.new {|b| :test_book_beta_recipe}
      end

      def some_helper
      end
    end

    class AnotherTestBook < DebugBar::RecipeBook::Base
      def duplicated_recipe
        Proc.new {|b| :another_test_book_duplicated_recipe}
      end

      def gamma_recipe
        Proc.new {|b| :another_test_book_gamma_recipe}
      end
    end

    before(:each) do
      @book_class = TestBook # TODO: This is a poor choice, we should create one just for testing.
      @book = @book_class.new

      @base_debug_bar = DebugBar::Base.new
      @debug_bar = DebugBar::Base.new {|bar| bar.add_recipe_book(TestBook); bar.add_recipe_book(AnotherTestBook)}
    end

    it 'should add recipe books by class' do
      @base_debug_bar.add_recipe_book(@book_class)

      @base_debug_bar.recipe_books.length.should == 1
      @base_debug_bar.recipe_books.first.should be_kind_of(@book_class)
    end

    it 'should add recipe books by instance' do
      @base_debug_bar.add_recipe_book(@book)

      @base_debug_bar.recipe_books.length.should == 1
      @base_debug_bar.recipe_books.first.should be_kind_of(@book_class)
    end

    it 'should return the list of known recipes' do
      @debug_bar.recipes.sort.should == [:beta, :duplicated, :gamma].sort
    end

    it 'should return a recipe callback if one is found' do
      callback = @debug_bar.recipe_callback(:beta)
      callback.should be_kind_of(Proc)
      callback.call.should == :test_book_beta_recipe
    end

    it 'should raise an Argument Error if a recipe is not found' do
      lambda {@debug_bar.recipe_callback(:zeta)}.should raise_error(ArgumentError)
    end

    it 'should use the last found instance of a recipe when it is duplicated' do
      callback = @debug_bar.recipe_callback(:duplicated)
      callback.should be_kind_of(Proc)
      callback.call.should == :another_test_book_duplicated_recipe
    end

  end

  describe 'subclass overrides' do

    class SubclassTestBook < DebugBar::RecipeBook::Base

      def beta_recipe
        Proc.new {|b| :test_book_beta_recipe}
      end

    end

    class SubclassInstanceTestBook < DebugBar::RecipeBook::Base

      def foo_recipe
        Proc.new {|b| :instance_test_book_foo_recipe}
      end

    end

    class SubclassTestBar < DebugBar::Base

      private

      def default_recipe_books
        return [SubclassTestBook, SubclassInstanceTestBook.new]
      end

      def default_recipes
        return [:beta]
      end

      def template_search_paths
        return :standin_for_an_array_of_pathnames
      end

    end

    before(:each) do
      @debug_bar = SubclassTestBar.new
    end

    it 'should add recipe books from the default recipe books method' do
      @debug_bar.recipe_books.length.should == 2
      @debug_bar.recipe_books.each {|book| book.should be_kind_of(DebugBar::RecipeBook::Base)}
    end

    it 'should add recipes from the default recipe method' do
      @debug_bar.recipes.sort.should == [:beta, :foo].sort
    end

    it 'should allow overriding of the template path' do
      @debug_bar.send(:template_search_paths).should == :standin_for_an_array_of_pathnames
    end

  end

end
