# rubocop:disable Metrics/AbcSize, Metrics/MethodLength
require 'logger'
require 'rack/commonlogger'
require_relative 'log_wrapper'
require 'sitehub/constants'

# Very heavily based on Rack::CommonLogger
class SiteHub
  module Logging
    class AccessLogger
      attr_reader :logger, :start_time

      include Constants

      FORMAT = %(%s - %s [%s] transaction_id:%s: "%s %s%s => %s %s" %d %s %0.4f\n).freeze
      ZERO_STRING = '0'.freeze
      STATUS_RANGE = 0..3

      def initialize(app, logger = ::Logger.new(STDOUT))
        @app = app
        @logger = LogWrapper.new(logger)
      end

      def call(env)
        start_time = Time.now

        @app.call(env).tap do |response|
          status, headers, _body = response.to_a
          log_message = format(log_template, *log_content(start_time, env, headers, env[REQUEST_MAPPING], status))
          logger.write(log_message)
        end
      end

      def log_content(began_at, env, header, mapped_request, status)
        now = Time.now
        [
          source_address(env),
          remote_user(env[RackHttpHeaderKeys::REMOTE_USER]),
          now.strftime(TIME_STAMP_FORMAT),
          env[RackHttpHeaderKeys::TRANSACTION_ID],
          env[RackHttpHeaderKeys::REQUEST_METHOD],
          env[RackHttpHeaderKeys::PATH_INFO],
          query_string(env[RackHttpHeaderKeys::QUERY_STRING]),
          mapped_url(mapped_request),
          env[RackHttpHeaderKeys::HTTP_VERSION],
          status.to_s[STATUS_RANGE],
          extract_content_length(header),
          now - began_at
        ]
      end

      def mapped_url(mapped_request)
        mapped_request ? mapped_request.mapped_url.to_s : EMPTY_STRING
      end

      def query_string(query_string)
        query_string.empty? ? EMPTY_STRING : QUESTION_MARK + query_string
      end

      def remote_user(remote_user)
        remote_user || '-'
      end

      def source_address(env)
        env[RackHttpHeaderKeys::X_FORWARDED_FOR] || env[RackHttpHeaderKeys::REMOTE_ADDR] || HYPHEN
      end

      def log_template
        FORMAT
      end

      def extract_content_length(headers)
        (value = headers[HttpHeaderKeys::CONTENT_LENGTH]) || (return HYPHEN)
        value.to_s == ZERO_STRING ? HYPHEN : value
      end
    end
  end
end
