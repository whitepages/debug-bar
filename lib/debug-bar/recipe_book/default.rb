require 'pp'
require 'awesome_print'

module DebugBar
  module RecipeBook
    class Default < Base

      def params_recipe(opts={})
        return Proc.new do |b|
          params_s = b[:params].pretty_inspect.gsub('<','&lt;')
          hidden = params_s.length > opts.fetch(:cutoff, 160)
          ['Params', params_s, :hidden => hidden]
        end
      end

      def session_recipe
        return Proc.new {|b| ['Session', b[:session].pretty_inspect.gsub('<','&lt;'), :hidden => false]}
      end

    end
  end
end
