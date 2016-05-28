# this helper module is for the benefit of middleware that may not otherwse respond to resolve.
# THis is to ensure that middleware wrapping the core forward proxy apps had the resolve method also.
#
class SiteHub
  module Resolver
    def resolve(*_args)
      self
    end
  end
end
