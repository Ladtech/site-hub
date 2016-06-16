class SiteHub
  module Equality
    def ==(other)
      other.is_a?(self.class)
      instance_variables.all? do |variable|
        instance_variable_get(variable) == other.instance_variable_get(variable)
      end
    end
  end
end
