class SiteHub
  class Collection < Hash
    class DuplicateVersionException < Exception
    end

    module ClassMethods
      def overrides
        @overrides ||= []
      end

      UNIQUE_LABELS_MSG = 'supply unique labels'.freeze

      def method_added(name)
        if name == :add && !overrides.include?(name)
          overrides << name
          alias_method :add_backup, :add

          send(:define_method, :add) do |id, value, *args|
            raise DuplicateVersionException, UNIQUE_LABELS_MSG if self[id]
            add_backup id, value, *args
          end
        end
      end
    end

    def valid?
      raise 'implement me'
    end

    def resolve
      raise 'implement me'
    end

    class << self
      def inherited(clazz)
        clazz.extend(ClassMethods)
      end
    end
  end
end
