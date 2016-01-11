require 'logger'
require 'rack/commonlogger'
require_relative 'log_wrapper'
require 'sitehub/constants'

#Very heavily based on Rack::CommonLogger
class SiteHub
  module Logging
    class AccessLogger
      attr_reader :logger, :start_time

      include Constants

      FORMAT = %{%s - %s [%s] transaction_id:%s: "%s %s%s => %s %s" %d %s %0.4f\n}.freeze
      PATH_INFO = RackHttpHeaderKeys::PATH_INFO
      REQUEST_METHOD = RackHttpHeaderKeys::REQUEST_METHOD
      SCRIPT_NAME = RackHttpHeaderKeys::SCRIPT_NAME
      QUERY_STRING = RackHttpHeaderKeys::QUERY_STRING
      X_FORWARDED_FOR = RackHttpHeaderKeys::X_FORWARDED_FOR
      REMOTE_ADDR = RackHttpHeaderKeys::REMOTE_ADDR
      HTTP_VERSION = RackHttpHeaderKeys::HTTP_VERSION
      REMOTE_USER = RackHttpHeaderKeys::REMOTE_USER
      TRANSACTION_ID = RackHttpHeaderKeys::TRANSACTION_ID
      CONTENT_LENGTH = HttpHeaderKeys::CONTENT_LENGTH
      ZERO_STRING = '0'
      STATUS_RANGE = 0..3

      def initialize app, logger = ::Logger.new(STDOUT)
        @app = app
        @logger = LogWrapper.new(logger)
      end

      def call env
        start_time = Time.now

        @app.call(env).tap do |response|
          status, headers, body = response.to_a
          log env, status, headers, env[REQUEST_MAPPING], start_time
        end
      end

      def log(env, status, header, mapped_request, began_at)
        now = Time.now
        length = extract_content_length(header)


        msg = log_template % [
            env[X_FORWARDED_FOR] || env[REMOTE_ADDR] || HYPHEN,
            env[REMOTE_USER] || "-",
            now.strftime(TIME_STAMP_FORMAT),
            env[TRANSACTION_ID],
            env[REQUEST_METHOD],
            env[PATH_INFO],
            env[QUERY_STRING].empty? ? EMPTY_STRING : QUESTION_MARK+env[QUERY_STRING],
            mapped_request ? mapped_request.mapped_url.to_s : EMPTY_STRING,
            env[HTTP_VERSION],
            status.to_s[STATUS_RANGE],
            length,
            now - began_at]

        logger.write(msg)
      end

      def log_template
        FORMAT
      end

      def extract_content_length(headers)
        value = headers[CONTENT_LENGTH] or return HYPHEN
        value.to_s == ZERO_STRING ? HYPHEN : value
      end
    end
  end
end