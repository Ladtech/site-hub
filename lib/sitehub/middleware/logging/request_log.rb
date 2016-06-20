class SiteHub
  module Middleware
    module Logging
      class RequestLog
        FORMAT = %(%s - %s [%s] transaction_id:%s: "%s %s%s => %s %s" %d %s %0.4f\n).freeze
        ZERO_STRING = '0'.freeze

        attr_reader :request, :response
        def initialize(request, response)
          @request = request
          @response = response
        end

        def to_s
          format(FORMAT, *data)
        end

        def extract_content_length
          (value = response.headers[Constants::HttpHeaderKeys::CONTENT_LENGTH]) || (return HYPHEN)
          value.to_s == ZERO_STRING ? HYPHEN : value
        end

        private

        def data
          [source_address, remote_user,
           response_time,
           request.transaction_id,
           request_method,
           request.path,
           query_string,
           mapped_url,
           request.http_version,
           status,
           extract_content_length,
           time_taken]
        end

        def time_taken
          response.time - request.time
        end

        def response_time
          response.time.strftime(TIME_STAMP_FORMAT)
        end

        def request_method
          request.request_method.upcase
        end

        def status
          response.status
        end

        def remote_user
          request.remote_user || HYPHEN
        end

        def source_address
          request.source_address || HYPHEN
        end

        def mapped_url
          request.mapped? ? request.mapping.mapped_url.to_s : EMPTY_STRING
        end

        def query_string
          query_string = request.query_string
          query_string.empty? ? EMPTY_STRING : QUESTION_MARK + query_string
        end
      end
    end
  end
end
