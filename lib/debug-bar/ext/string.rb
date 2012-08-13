require 'cgi'

module DebugBar
  module Ext
    module String

      def html_escape
        return CGI.escapeHTML(self)
      end

    end
  end
end


unless( String.methods.include?(:html_escape) )
  String.send(:include, DebugBar::Ext::String)
end
