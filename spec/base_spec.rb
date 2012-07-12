require 'spec_helper'

describe DebugBar::Base do

  describe 'callbacks' do

    it 'should be able to initialize with recipes' do
      debug_bar = DebugBar::Base.new(:params, :session)
      debug_bar.callbacks.length.should == 2
    end

    before(:each) do
      @debug_bar = DebugBar::Base.new
    end

    it 'should register blocks' do
      @debug_bar.callbacks.should == []

      @debug_bar.add {|b| ["Test Block", "Test Content", {}]}

      @debug_bar.callbacks.length.should == 1
      @debug_bar.callbacks.first.should be_kind_of(Proc)
    end

    it 'should register recipes' do
      @debug_bar.callbacks.should == []

      @debug_bar.add(:params)

      @debug_bar.callbacks.length.should == 1
      @debug_bar.callbacks.first.should be_kind_of(Proc)
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

      puts html.inspect

      html.index("||get is true||").should_not be_nil
    end

    it 'should render recipes' do
      @debug_bar.add(:params)
      params = {:given_name => 'Amelia', :family_name => 'Pond'}

      html = @debug_bar.render(binding)

      html.should be_kind_of(String)
      html.should_not be_empty

      html.index('Amelia').should_not be_nil
      html.index(':given_name').should_not be_nil
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

    it 'should default :hidden option based on session'

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

end
