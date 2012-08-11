require 'active_support/all'
require 'pathname'
require 'erubis'


require_relative 'ext'

# DebugBar is the module namespace for this gem.  For the DebugBar base class,
# see DebugBar::Base.
module DebugBar
  # = Overview
  #
  # DebugBar::Base provides the base methods for all debug bars.
  #
  # At it's core, a DebugBar is instantiated with +initialize+, gets callbacks
  # added with +add_callback+, and then is rendered with +render+.
  #
  # Additionally, RecipeBook classes or instance may be added to the DebugBar
  # via +add_recipe_book+ so that pre-made callbacks may be easily added to the
  # DebugBar instance via add_callbacks.
  #
  # See the README for example usage.
  #
  # = Subclassing
  #
  # This class is often subclassed to give DebugBars with special behaviors.
  # If you make a subclass, define <b>private</b> overrides to these methods:
  # [+default_recipe_books+] Provide a list of recipe books to make available to all instances.
  # [+default_recipes+] Add a list of recipe callbacks to all instances.
  # [+template_search_paths+] Override the default formatting template search path.
  class Base

    # The search path for formatting templates, such as the layout and callback box.
    # NOTE: This is separate from templates that are used in recipes!
    TEMPLATE_SEARCH_PATHS = [
      (Pathname.new(__FILE__).dirname + '../templates')
    ].map {|path| path.expand_path}

    # Initialize a new debug bar.  This may optionally take
    # one or more recipe symbols as arguments.
    def initialize(*recipes)
      @callbacks = []
      @recipe_books = []
      default_recipe_books.each {|book| add_recipe_book(book)}
      yield self if block_given?
      (default_recipes()|recipes).each {|recipe| add_recipe(recipe)}
    end

    # Returns a copy of the raw list of callbacks.
    attr_reader :callbacks

    # Returns a copy of the list of recipe book instances.
    attr_reader :recipe_books

    # Adds a recipe book class or instance to the recipe book list for
    # this debug bar.
    #
    # Returns self to support functional programming styles.
    def add_recipe_book(book)
      @recipe_books << (book.kind_of?(Class) ? book.new : book)
      return self
    end

    # Returns the list of recipes recognized by this debug bar.
    def recipes
      return @recipe_books.inject([]) {|list,book| list | book.recipes}
    end

    # Returns the most recently added occurance of the given recipe.
    def recipe_callback(recipe, *args)
      book = @recipe_books.reverse.find {|book| book.include?(recipe)}
      raise ArgumentError, "Could not find recipe #{recipe.inspect}", caller if book.nil?
      return book.recipe(recipe, *args)
    end

    # Adds a callback.
    #
    # Takes either a recipe (by symbol) or a block.
    #
    # The block takes a single argument, the binding of the render context,
    # and should return either a string, or an array of [title, content, opts].
    #
    # Advanced users can call a recipe by name, and provide additional arguments
    # to configure the recipe further.  These arguments are defined by the
    # recipe factory method, but usually are via an options hash.
    #
    # Returns self to support functional programming styles.
    def add_callback(recipe=nil, *args, &callback)
      callback_proc = (callback || recipe_callback(recipe, *args))
      raise ArgumentError, "Expected callback to respond to `call': #{callback_proc.inspect}", caller unless callback_proc.respond_to?(:call)
      @callbacks << callback_proc
      return self
    end
    alias_method :add_recipe, :add_callback
    alias_method :add, :add_callback

    # Renders the debug bar with the given binding.
    def render(eval_binding)
      # Decorate the binding here (NOT in private methods where we don't want automatic behavior)!
      eval_binding.extend(DebugBar::Ext::Binding)
      return render_layout(eval_binding)
    end

    private

    # An initialization callback for adding default recipe books to instances;
    # this should return an array of recipe book classes or instances.
    #
    # On the base class, this returns an empty array; subclasses should override this.
    def default_recipe_books
      return []
    end

    # An initialization callback for adding default recipes to the callbacks
    # array.
    #
    # On the base class, this returns an empty array; subclasses should override this.
    def default_recipes
      return []
    end

    # Returns the template search paths for this instance.
    #
    # Paths should be Pathname instances
    #
    # Subclasses may override this to change the search path for the formatting
    # templates such as the layout and callback_box templates.
    def template_search_paths
      return TEMPLATE_SEARCH_PATHS
    end

    # Looks for the given remplate name within the template search paths, and
    # returns a string containing its contents.  The name may be a symbol or string.
    #
    # Template names automatically have '.html.erb' appended to them, so call
    #   read_template(:foo)
    # instead of
    #   read_template('foo.html.erb')
    def read_template(template)
      template_name = "#{template}.html.erb"
      template_path = template_search_paths.map {|base_path| (base_path + template_name).expand_path}.find {|p| p.exist? && p.file?}
      raise ArgumentError, "Unknown template #{template_name.inspect}.  Not in #{template_search_paths.inspect}", caller if template_path.nil?
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
      return @callbacks.map {|callback| render_callback(callback, eval_binding)}.join("\n")
    end

    # Renders the given callback in the given binding.
    def render_callback(callback, eval_binding)
      # Get the result of the callback
      obj = begin
              callback.respond_to?(:call) ? callback.call(eval_binding) : callback
            rescue Exception => error
              render_error_callback(error)
            end

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
      return Erubis::Eruby.new( read_template(:callback_box) ).result(:title => title, :content => content, :opts => opts).html_safe
    end

    def render_error_callback(error, opts={})
      return [
        opts.fetch(:title, '**ERROR'),
        ("#{error.class}: #{error.message}<br/>" + error.backtrace.join("<br/>")).html_escape,
        {}
      ]
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
