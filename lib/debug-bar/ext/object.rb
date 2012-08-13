require 'awesome_print'

module DebugBar
  module Ext
    module Object

      def awesome_print(opts={})
        return self.ai(opts)
      end

      def awesome_print_html
        return self.awesome_print(:html => true)
      end

    end
  end
end


Object.send(:include, DebugBar::Ext::Object)
