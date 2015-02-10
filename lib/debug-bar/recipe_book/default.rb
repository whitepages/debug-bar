require 'pp'
require 'awesome_print'
require 'cgi'
require 'socket'

module DebugBar
  module RecipeBook
    # A default RecipeBook with recipes useful for Rails applications.
    class Default < Base

      # Displays params in a user readable fashion.
      #
      # If the :cutoff option is given, it auto-hides when the params are
      # more characters in length than the cutoff, otherwise it defaults to
      # a sane length.
      def params_recipe(opts={})
        return Proc.new do |b|
          params_s = b[:params].awesome_print_html
          ['Params', params_s, {:id => 'params'}]
        end
      end

      # Displays the session in a pretty printed way.
      def session_recipe
        return Proc.new {|b| ['Session', b[:session].awesome_print_html, {:id => 'session'}]}
      end

      # Displays the cookies.
      def cookies_recipe
        return Proc.new {|b| ['Cookies', b[:cookies].awesome_print_html, {:id => 'cookies'}]}
      end

      def exception_recipe
        return Proc.new do |b|
          exception = b.eval("request.env[\"action_dispatch.exception\"]")
          exception ? ['Exception', exception.awesome_print_html, {:id => 'exceptions'}] : nil
        end
      end

      def host_recipe
        return Proc.new do |b|
          host = Socket.gethostname
          ['Host', host.awesome_print_html, { id: 'host' }]
        end
      end
    end
  end
end
