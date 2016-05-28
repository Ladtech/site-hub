require 'uuid'
require 'sitehub/constants'
class SiteHub
  class TransactionId
    include Constants
    def initialize(app)
      @app = app
    end

    def call(env)
      env[RackHttpHeaderKeys::TRANSACTION_ID] ||= UUID.generate(:compact)
      @app.call env
    end
  end
end
