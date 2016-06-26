class SiteHub
  module Equality
    module ClassMethods
      def transient_fields
        @transient_fields ||= []
      end

      def transient(*fields)
        transient_fields.concat(fields.collect { |field| "@#{field}".to_sym })
      end
    end
    def self.included(clazz)
      clazz.extend(ClassMethods)
    end

    def ==(other)
      fields = instance_variables.find_all { |field| !_clazz.transient_fields.include?(field) }
      fields.all? do |variable|
        instance_variable_get(variable) == other.instance_variable_get(variable)
      end
    end

    def _clazz
      self.class
    end
  end
end
