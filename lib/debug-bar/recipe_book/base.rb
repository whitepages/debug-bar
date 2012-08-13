require 'pathname'

module DebugBar
  # RecipeBook is the module namespace for the RecipeBooks provided in this
  # gem.  For the base RecipeBook, see RecipeBook::Base.
  module RecipeBook
    # The base class for all recipe subclasses.  Provides common convenience
    # methods for recipe use.  Essentially, these are factory methods that
    # lazy generate common configurable callbacks on demand.
    #
    # Subclasses need only to define factory instance methods that meet the
    # following rules:
    # 1. The method name must be the recipe name suffixed with `_recipe'.  So
    #    the recipe
    #      :foo
    #    would have method name
    #      foo_recipe
    # 2. Recipe factory methods <b>MUST</b> return a valid callback when no arguments
    #    are given, that is
    #      book.foo_recipe()
    #    must work.
    # 3. The result of a recipe factory method must be a Proc object that
    #    conforms to the requirements of the Procs registered with +add_callback+
    #    on the DebugBar::Base class.
    # 4. Recipe methods <i>may</i> take an additional argument, which is an
    #    options hash for special configuration when using +add_callback+ on
    #    DebugBar::Base instances.  For example, one can then us
    #
    # For example, the following recipe renders the params hash from the given
    # binding:
    #
    #   def params_recipe(opts={})
    #     Proc.new do |b|
    #       body = (opts[:formatter] == :pretty_inspect) ? b[:params].pretty_inspect : b[:params].inspect
    #       ['Params', body.gsub('<','&lt;'), :hidden => (body.length>160)]
    #     end
    #   end
    #
    # It could then be added to the DebugBar like so:
    #
    #   debug_bar.add(:params)
    #   debug_bar.add(:params, :formatter => :pretty_inspect)
    class Base

      # Returns a list of recipes known to this class.
      def recipes
        return self.methods.select {|m| m.to_s =~ /_recipe$/}.map {|m| m.to_s.gsub(/_recipe$/,'').to_sym}
      end

      # Returns true if the given recipe is known.
      def include?(recipe)
        return self.respond_to?("#{recipe}_recipe")
      end
      alias_method :has_recipe?, :include?

      # Generates the given recipe.
      # All recipes are expected to accept no arguments, but may optionally
      # take more.  Optional arguments given to this method are passed through
      # to the recipe method.
      def recipe(recipe, *args, &block)
        return self.send("#{recipe}_recipe", *args, &block)
      end
      alias_method :[], :recipe

      # Retrieves the template search paths for this recipe instance as
      # fully expanded Pathname instances.
      #
      # While subclasses <i>may</i> override this method, it is preferrable
      # for them to use the setter (+template_search_paths=+) during instance
      # initialization, as the setter sanitizes the input.
      def template_search_paths
        return @template_search_paths ||= []
      end

      # Sets the template search paths for this recipe instance, converting
      # to pathname objects as necessary.
      def template_search_paths=(paths)
        @template_search_paths = paths.map {|path| Pathname.new(path.to_s).expand_path }
      end

      private

      # Renders the first matching template found in the search paths.  Passed
      # symbols/names are automatically suffixed with 'html.erb'.  The template
      # name may be a symbol or string.
      #
      # Optionally, one can pass in :locals, which is a hash of local variables
      # to render in the template.
      def render_template(template, opts={})
        return Erubis::Eruby.new( read_template(template) ).result( opts.fetch(:locals, {}) ).html_safe
      end

      # Reads the given template and returns the string of its contents.
      # The template name may be either a symbol or string.
      def read_template(template)
        template_name = "#{template}.html.erb"
        template_path = template_search_paths.map {|base_path| (base_path + template_name).expand_path}.find {|p| p.exist? && p.file?}
        raise ArgumentError, "Unknown template #{template_name.inspect}.  Not in #{template_search_paths.inspect}", caller if template_path.nil?
        return template_path.read
      end

    end
  end
end
