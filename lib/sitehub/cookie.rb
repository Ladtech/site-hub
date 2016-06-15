require 'sitehub/cookie/attribute'
require 'sitehub/cookie/flag'
require 'sitehub/constants'
class SiteHub
  class Cookie
    attr_reader :attributes_and_flags, :name_attribute
    include Constants

    FIRST = 0

    def initialize(cookie_string)
      pairs = cookie_string.split(SEMICOLON).map do |entry|
        if entry.include?(EQUALS_SIGN)
          Cookie::Attribute.new(*entry.split(EQUALS_SIGN))
        else
          Cookie::Flag.new(entry)
        end
      end

      name_attribute = pairs.delete_at(FIRST)
      @attributes_and_flags = pairs
      @name_attribute = Cookie::Attribute.new(name_attribute.name.to_s, name_attribute.value)
    end

    def name
      name_attribute.name
    end

    def value
      name_attribute.value
    end

    def find(name)
      attributes_and_flags.find { |entry| entry.name == name }
    end

    def ==(other)
      other.is_a?(self.class) &&
        sorted_attributes_and_flags(attributes_and_flags) == sorted_attributes_and_flags(other.attributes_and_flags)
    end

    def sorted_attributes_and_flags(attributes_and_flags)
      attributes_and_flags.sort { |entry_a, entry_b| entry_a.name <=> entry_b.name }
    end

    def to_s
      [name_attribute].concat(attributes_and_flags).join(SEMICOLON_WITH_SPACE)
    end
  end
end
