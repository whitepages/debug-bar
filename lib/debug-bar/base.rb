require 'pathname'
require 'erubis'
require 'awesome_print'
require 'active_support/all'


require_relative 'recipes'

module DebugBar
  # The base debug bar class.
  #
  # DebugBar is generally rendered within a context by being given a render
  # binding.  For example <code>debug_bar.render(binding)</code>.
  class Base

    # The search path for base templates, such as the layout and callback box.
    # NOTE: This is separate from templates that might be used in recipes.
    TEMPLATE_SEARCH_PATHS = [
      (Pathname.new(__FILE__).dirname + '../templates')
    ].map {|path| path.expand_path}

    # Initialize a new debug bar.  This may optionally take
    # one or more recipe symbols as arguments.
    def initialize(*recipes)
      @callbacks = []
      recipes.each {|recipe| add(recipe)}
      yield self if block_given?
    end

    attr_reader :callbacks
    attr_writer :callbacks

    # Adds a callback.
    #
    # Takes either a recipe symbol, or a block.
    #
    # The block takes a single argument, the binding of the render context,
    # and should return an array of [title, content, opts].
    def add(recipe=nil, &callback)
      @callbacks << (callback || Recipes.new.send(recipe.to_sym))
      return self
    end

    # Renders the debug bar with the given binding.
    def render(eval_binding)
      return render_layout(eval_binding)
    end

    private

    # Looks for the given remplate name within the template search paths.
    #
    # Template names automatically have '.html.erb' appended to them, so call
    # <code>read_template('foo')</code> instead of <code>read_template('foo.html.erb').
    def read_template(template)
      #puts  TEMPLATE_SEARCH_PATHS.map {|base_path| (base_path + "#{template}.html.erb").expand_path}.inspect
      template_path = TEMPLATE_SEARCH_PATHS.map {|base_path| (base_path + "#{template}.html.erb").expand_path}.find {|p| p.exist? && p.file?}
      raise ArgumentError, "Unknown template #{template.inspect}.  Not in #{TEMPLATE_SEARCH_PATHS.inspect}" if template_path.nil?
      return template_path.read
    end

    # Renders the callbacks and then renders the layout--all in the given
    # binding--inserting the callbacks into the layout; returns an html_safe string.
    def render_layout(eval_binding)
      content = render_callbacks(@callbacks, eval_binding)
      return Erubis::Eruby.new(read_template(:layout)).result(:content => content).html_safe
    end

    # Returns the contactinated set of rendered callbacks usnig the given binding.
    def render_callbacks(callbacks, eval_binding)
      return callbacks.map {|callback| render_callback(callback, eval_binding)}.join("\n")
    end

    # Renders the given callback in the given binding.
    def render_callback(callback, eval_binding)
      # Get the result of the callback
      obj = callback.call(eval_binding)

      # Extract the title, content, and opts from the result
      title, content, opts = case obj
      when Array
        obj
      else
        ['Debug', obj.to_s, {}]
      end
      opts ||= {}

      # reverse merge the opts
      default_hidden = opts[:id].nil? ? true : !cookie_include?(opts[:id], eval_binding)
      opts = {:hidden => default_hidden}.merge(opts||{})

      # Render the callback in a box
      return Erubis::Eruby.new(read_template(:callback_box)).result(:title => title, :content => content, :opts => opts).html_safe
    end

    # A helper method that--if the eval_binding defines a cookies hash, and
    # that hash has a :debug_bar key, returns true if it contains the given
    # id; otherwise it returns false.
    #
    # TODO: This code should be refactored to support more use cases as they appear.
    def cookie_include?(id, eval_binding)
      debug_bar = eval_binding.eval("cookies[:debug_bar]")
      debug_bar.nil? ? false : debug_bar.split(',').include?(id)
    end
  end
end
