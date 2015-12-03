require 'sitehub/constants'
require 'sitehub/builder'
class SiteHub
  class << self
    def build &block
      Builder.new(&block).build
    end
  end
end
