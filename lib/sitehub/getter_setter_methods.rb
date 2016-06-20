class SiteHub
  module GetterSetterMethods
    def getter_setters(*method_names)
      method_names.each do |method_name|
        getter_setter method_name.to_sym
      end
    end

    def getter_setter(method_name, default = nil)
      define_method method_name do |arg = nil|
        attribute_name = "@#{method_name}"
        if arg
          instance_variable_set(attribute_name, arg)
          self
        else
          instance_variable_get(attribute_name) || default
        end
      end
    end
  end
end
