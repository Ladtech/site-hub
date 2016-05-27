module Async
  class ResponseHandler < EM::DefaultDeferrable
    attr_reader :last_response, :callback_args

    alias arg callback_args

    def succeed(arg)
      sitehub_response = arg[:downstream_response]
      instance_variable_set(:@arg, arg)
      status, headers, body = *sitehub_response.to_a
      rack_response = Rack::Response.new(body, status, headers)
      instance_variable_set(:@last_response, rack_response)
      EM.stop
    end
  end
end
