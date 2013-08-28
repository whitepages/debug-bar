module DebugBar
  # A default DebugBar implementation suitable for use in a Ruby On Rails
  # application layout template.
  #
  # This, of course, may be customized, typically by creating an initializer
  # file at config/initializers/debug_bar.rb, and populating like so:
  #
  #   DEBUG_BAR = DebugBar::Default.new do |bar|
  #     bar.add {|b| ['Time', Time.now]}
  #   end
  class Default < Base

    private

    # Override superclass method to provide the necessary cookbook.
    def default_recipe_books
      return [RecipeBook::Default]
    end

    # The recipes added to this debug bar by default.
    def default_recipes
      return [:params, :session, :exception]
    end

  end
end
