=begin
TODO - this helper module is for the benefit of middleware that may not otherwse respond to resolve. THis is to ensure that middleware wrapping the core forward proxy apps had the resolve method also.

=end
class SiteHub
  module Resolver
    def resolve(*args)
      self
    end
  end
end