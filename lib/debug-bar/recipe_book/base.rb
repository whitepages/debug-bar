require 'pathname'

module DebugBar
  # RecipeBook is the module namespace for the RecipeBooks provided in this
  # gem.  For the base RecipeBook, see RecipeBook::Base.
  module RecipeBook
    # The base class for all recipe subclasses.  Provides common convenience
    # methods for recipe use.
    #
    # Subclasses should define factory instance methods that take no arguments
    # and return callbacks as Procs; This is so that DebugBars can be
    # instantiated with recipe names as callbacks.
    #
    # Doing it this way also allows for on-demand, lazy instantiation
    # of the callback Procs.
    #
    # Advanced purposes can have optional arguments to the factory methods for
    # customization; these are then explicitly added to the DebugBar.  For example:
    #   debug.add( &SomeRecipeClass.params_recipe(:formatter => :pretty) )
    #
    # Recipe method names must be suffixed with '_recipe' for introspection and
    # namespacing purposes.
    class Base

      # Retrieves the template search paths for this recipe instance as
      # fully expanded Pathname instances.
      def self.template_search_paths
        return @template_search_paths ||= []
      end

      # Sets the template search paths for this recipe instance.
      def self.template_search_paths=(paths)
        @template_search_paths = paths.map {|path| Pathname.new(path.to_s).expand_path }
      end

      # Returns a list of recipes known to this class.
      def recipes
        return self.methods.select {|m| m.to_s =~ /_recipe$/}.map {|m| m.to_s.gsub(/_recipe$/,'').to_sym}
      end

      # Returns true if the given recipe is known.
      def include?(recipe)
        return self.respond_to?("#{recipe}_recipe")
      end
      alias_method :has_recipe?, :include?

      # Gets the given recipe.
      def [](recipe)
        return self.send("#{recipe}_recipe")
      end

      private

      # Renders the first matching template found in the search paths.  Passed
      # symbols/names are automatically suffixed with 'html.erb'.
      #
      # Optionally, one can pass in :locals, which is a hash of local variables
      # to render in the template.
      def render_template(template, opts={})
        return Erubis::Eruby.new( read_template(template) ).result( opts.fetch(:locals, {}) ).html_safe
      end

      # Reads the given template and returns the string of its contents.
      def read_template(template)
        template_name = "#{template}.html.erb"
        template_path = self.template_search_paths.map {|base_path| (base_path + template_name).expand_path}.find {|p| p.exist? && p.file?}
        raise ArgumentError, "Unknown template #{template_name.inspect}.  Not in #{TEMPLATE_SEARCH_PATHS.inspect}", caller if template_path.nil?
        return template_path.read
      end

      # Returns the classes template search paths.
      def template_search_paths
        return self.class.template_search_paths
      end

    end
  end
end
