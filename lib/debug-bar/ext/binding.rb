module DebugBar
  module Ext
    module Binding
      VARIABLE_PATTERN = /^(@{1,2}|\$)?([_a-zA-Z]\w*)$/

      # Returns the value of the given variable symbol within the binding.
      # Supports local, instance, class, or global variables, as well as constants.
      def [](var)
        raise NameError, "#{var.inspect} is not a valid variable name" unless var.to_s =~ VARIABLE_PATTERN
        return self.eval(var.to_s)
      end

    end
  end
end
