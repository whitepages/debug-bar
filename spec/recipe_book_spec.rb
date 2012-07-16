require 'spec_helper'

describe DebugBar::RecipeBook::Base do

  class RecipeTestBook < DebugBar::RecipeBook::Base

    def time_recipe
      return Proc.new {|b| ['Time', Time.now, {}]}
    end

    # Places all key value pairs between vertical pipes.
    # Ex: {:foo => 'bar'} --> '|foo|bar|'
    def opts_recipe(opts={})
      return Proc.new {|b| ['Opts', '|' + opts.to_a.flatten.join('|') + '|', {}]}
    end

    def render_recipe(opts={})
      locals = {:content => 'River Song'}.merge(opts)
      return Proc.new {|b| ['Render', render_template(:content, :locals => locals), {}]}
    end

    def helper_method
      return :helper_method_result_standin
    end

  end

  class BindingContext

    def fetch_binding
      return binding
    end

  end

  before(:each) do
    @book = RecipeTestBook.new
  end

  describe 'recipe introspection' do

    it 'should give the list of all known recipes as symbols' do
      @book.recipes.sort.should == [:time, :opts, :render].sort
    end

    it 'should allow checking for knowledge of a recipe by symbol' do
      @book.include?(:time).should be_true
      @book.include?(:zeta).should be_false
    end

    it 'should allow checking for knowledge of a recipe by string' do
      @book.include?('time').should be_true
      @book.include?('zeta').should be_false
    end

  end

  describe 'recipe fetching' do

    before(:each) do
      @binding = BindingContext.new.fetch_binding
    end

    [:time, 'time'].each do |key|
      it "should return the generated callback of a recipe reference by #{key.class.name}" do
        recipe = @book.recipe(key)
        recipe.should be_kind_of(Proc)
        title, body = recipe.call(@binding)
        title.should == 'Time'
      end
    end

    it 'should pass an options hash to the recipe when given.' do
      recipe = @book.recipe(:opts, :name => 'Amelia Pond')
      recipe.should be_kind_of(Proc)
      title, body= recipe.call(@binding)
      title.should == 'Opts'
      body.should == '|name|Amelia Pond|'
    end

    it 'should get the callback for a recipe that has opts even when they are not given.' do
      recipe = @book.recipe(:opts)
      recipe.should be_kind_of(Proc)
      title, body= recipe.call(@binding)
      title.should == 'Opts'
      body.should == '||'
    end

    it 'should alias [] to recipe' do
      @book.method(:[]).should == @book.method(:recipe)
    end

  end

  describe 'templates' do

    before(:each) do
      @book.send(:template_search_paths=, [Pathname.new(__FILE__).dirname + 'support' + 'templates'])
    end

    it 'should have configurable template search paths' do
      @book = RecipeTestBook.new # Need a clean book for this test.
      @book.send(:template_search_paths).should == []

      @book.send(:template_search_paths=, ['foo', 'bar'])

      @book.send(:template_search_paths).each {|pn| pn.should be_kind_of(Pathname)}
      @book.send(:template_search_paths).first.basename.to_s.should == 'foo'
      @book.send(:template_search_paths).last.basename.to_s.should == 'bar'
    end

    it 'should read template names by symbol from the search path' do
      template = @book.send(:read_template, :basic)

      template.should be_kind_of(String)
      template.index('id="basic"').should_not be_nil
    end

    it 'should read template names by string from the search path' do
      template = @book.send(:read_template, 'basic')

      template.should be_kind_of(String)
      template.index('id="basic"').should_not be_nil
    end

    it 'should raise an ArgumenError when the template is not found' do
      lambda {@book.send(:read_template, :gallifrey)}.should raise_error(ArgumentError)
    end

    it 'should render the template' do
      html = @book.send(:render_template, :basic)
      html.index('id="basic"').should_not be_nil
    end

    it 'should render the template with :locals' do
      html = @book.send(:render_template, :content, :locals => {:content => 'The Doctor'})

      html.index('id="content"').should_not be_nil
      html.index('River Song').should be_nil
      html.index('The Doctor').should_not be_nil
    end

    it 'should render the template within a recipe' do
      title, html = @book.recipe(:render).call(@binding)

      html.index('id="content"').should_not be_nil
      html.index('River Song').should_not be_nil
      html.index('The Doctor').should be_nil
    end

    it 'should render the template with locals from within a recipe' do
      title, html = @book.recipe(:render, :content => 'The Doctor').call(@binding)

      html.index('id="content"').should_not be_nil
      html.index('River Song').should be_nil
      html.index('The Doctor').should_not be_nil
    end

  end

end
