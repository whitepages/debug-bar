module DebugBar
  class Default < Base

    def initialize(*recipes)
      recipes = [:params, :session] | recipes
      super(*recipes)
    end

  end
end
