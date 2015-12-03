class SiteHub
  module Rules
    def rule rule=nil
      return @rule unless rule
      @rule = rule
    end

    def applies?(env)
      return true unless rule
      rule.call(env) == true
    end
  end
end