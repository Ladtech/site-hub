require 'json'
class SiteHub
  class ConfigServer
    BAD_JSON_MSG = 'Illegal JSON returned from config server: %s'.freeze
    UNABLE_TO_CONTACT_SERVER_MSG = 'Unabled to contact server: %s'.freeze
    NON_200_RESPONSE_MSG = 'Config server did not respond with a 200, got %s'.freeze

    class Error < StandardError
    end

    attr_reader :server_url, :http_client
    def initialize(url)
      @server_url = url
      @http_client = Faraday.new(ssl: { verify: false }) do |con|
        con.adapter :em_synchrony
      end
    end

    def get
      response = http_client.get(server_url)
      raise Error, NON_200_RESPONSE_MSG % response.status unless response.status == 200
      parse_response(response.body)
    rescue Faraday::Error => e
      raise Error, UNABLE_TO_CONTACT_SERVER_MSG % e.message
    end

    def parse_response(response_body)
      JSON(response_body, symbolize_names: true)
    rescue JSON::ParserError
      raise Error, BAD_JSON_MSG % response_body
    end
  end
end
