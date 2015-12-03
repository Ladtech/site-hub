class SiteHub
  class Collection < Hash
    class DuplicateVersionException < Exception;
    end

    def valid?
      raise "implement me"
    end

    def resolve
      raise "implement me"
    end

    class << self
      def inherited clazz

        def clazz.overrides
          @overrides ||=[]
        end

        def clazz.method_added(name)
          if name == :add && !overrides.include?(name)
            overrides << name
            alias_method :add_backup, :add

            self.send(:define_method, :add) do |id, value, *args|
              raise DuplicateVersionException, 'supply unique labels' if self[id]
              add_backup id, value, *args
            end
          end
        end
      end
    end
  end
end