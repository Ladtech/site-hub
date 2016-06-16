class SiteHub
  module Memoize

    def memoize(method)
      method_alias = "_#{method}"
      alias_method method_alias, method

      define_memoized_method(method, method_alias)
    end

    private

    def define_memoized_method(method, method_alias)
      define_method(method) do |*args, &block|
        attribute = "@#{method}"
        return instance_variable_get(attribute) if instance_variable_defined? attribute

        send(method_alias, *args, &block).tap do |result|
          instance_variable_set(attribute, result)
        end
      end
    end
  end
end
