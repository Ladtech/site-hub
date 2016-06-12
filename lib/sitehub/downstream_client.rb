require 'sitehub/request'
require 'sitehub/request_mapping'
require 'sitehub/rules'
require 'sitehub/resolver'
require 'faraday'
require 'sitehub/constants'

# Requirements: https://www.mnot.net/blog/2011/07/11/what_proxies_must_do
# 1. remove hop by hop headers
# 2. detect bad framing: where content length and content-encoding clash or are incorrect
# 3. fix conflicts between header and URL header
# 4. insert via (optional)
# 5. Expect header (optional)

class SiteHub
  class DownstreamClient
    include Constants

    attr_reader :http_client

    def initialize
      @http_client = Faraday.new(ssl: { verify: false }) do |con|
        con.adapter :em_synchrony
      end
    end

    def call(sitehub_request)
      response = http_client.send(sitehub_request.request_method, sitehub_request.uri) do |request|
        request.headers = sitehub_request.headers
        request.body = sitehub_request.body
        request.params = sitehub_request.params
      end

      Rack::Response.new(response.body, response.status, response.headers)
    end
  end
end
