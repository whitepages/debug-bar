require 'pp'

module DebugBar
  class Recipes

    def params
      return Proc.new do |b|
        params = b.eval('params')
        params_s = params.pretty_inspect.gsub('<','&lt;')
        hidden = params_s.length>160
        ['Params', params_s, :hidden => hidden]
      end
    end

    def session
      return Proc.new {|b| ['Session', get(b,:session).pretty_inspect.gsub('<','&lt;'), :hidden => false]}
    end

    private

    def get(bind, *vars)
      return *(vars.map {|v| bind.eval(v.to_s)})
    end

  end
end
