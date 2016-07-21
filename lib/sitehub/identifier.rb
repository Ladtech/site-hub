class SiteHub
  class Identifier
    attr_reader :id, :components

    def initialize(id)
      @components = id.to_s.split('|').collect(&:to_sym)
    end

    def child_label(label)
      components.empty? ? label : "#{self}|#{label}"
    end

    def root
      components.first
    end

    def sub_id
      Identifier.new(components[1..-1].join('|'))
    end

    def valid?
      !@components.empty?
    end

    def to_s
      components.join('|')
    end

    def to_sym
      to_s.to_sym
    end

    def ==(other)
      other.respond_to?(:to_sym) && to_sym == other.to_sym
    end
  end
end
