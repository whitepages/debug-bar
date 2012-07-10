require 'pathname'
require 'erubis'
require 'awesome_print'

require_relative 'recipes'

module DebugBar
  class Base

    TEMPLATE_SEARCH_PATHS = [
      (Pathname.new(__FILE__).dirname + '../templates')
    ].map {|path| path.expand_path}

    def initialize(*recipes)
      @callbacks = []
      recipes.each {|recipe| add(recipe)}
      yield self if block_given?
    end

    attr_reader :callbacks
    attr_writer :callbacks

    # Takes either a pre-made recipe symbol, or a block.
    # The block takes a single argument, the binding of the render context,
    # and should return an html string.
    def add(recipe=nil, &callback)
      @callbacks << (callback || Recipes.new.send(recipe.to_sym))
    end

    def render(eval_binding)
      return render_layout(eval_binding)
    end

    private

    def read_template(template)
      #puts  TEMPLATE_SEARCH_PATHS.map {|base_path| (base_path + "#{template}.html.erb").expand_path}.inspect
      template_path = TEMPLATE_SEARCH_PATHS.map {|base_path| (base_path + "#{template}.html.erb").expand_path}.find {|p| p.exist? && p.file?}
      raise ArgumentError, "Unknown template #{template.inspect}.  Not in #{TEMPLATE_SEARCH_PATHS.inspect}" if template_path.nil?
      return template_path.read
    end

    def render_layout(eval_binding)
      content = render_callbacks(@callbacks, eval_binding)
      return Erubis::Eruby.new(read_template(:layout)).result(:content => content).html_safe
    end

    def render_callbacks(callbacks, eval_binding)
      return callbacks.map {|callback| render_callback(callback, eval_binding)}.join("\n")
    end

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
    
    def cookie_include?(id, eval_binding)
      debug_bar = eval_binding.eval("cookies[:debug_bar]")
      debug_bar.nil? ? false : debug_bar.split(',').include?(id)
    end
  end
end
