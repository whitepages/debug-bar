require 'pp'
require 'awesome_print'

module DebugBar
  module RecipeBook
    # A default RecipeBook with recipes useful for Rails applications.
    class Default < Base

      # Displays params in a user readable fashion.
      #
      # If the :cutoff option is given, it auto-hides when the params are
      # more characters in length than the cutoff, otherwise it defaults to
      # a sane length.
      #
      # TODO: Do better HTML entity encoding in inspect.
      def params_recipe(opts={})
        return Proc.new do |b|
          params_s = b[:params].pretty_inspect.gsub('<','&lt;')
          hidden = params_s.length > opts.fetch(:cutoff, 160)
          ['Params', params_s, :hidden => hidden]
        end
      end

      # Displays the session in a pretty printed way.
      #
      # TODO: Do better HTML entity encoding in inspect.
      def session_recipe
        return Proc.new {|b| ['Session', b[:session].pretty_inspect.gsub('<','&lt;'), :hidden => false]}
      end

    end
  end
end
