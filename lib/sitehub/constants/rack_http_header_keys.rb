class SiteHub
  module Constants
    module RackHttpHeaderKeys
      PATH_INFO      = 'PATH_INFO'.freeze
      REQUEST_METHOD = 'REQUEST_METHOD'.freeze
      SCRIPT_NAME    = 'SCRIPT_NAME'.freeze
      QUERY_STRING   = 'QUERY_STRING'.freeze
      X_FORWARDED_FOR = 'HTTP_X_FORWARDED_FOR'.freeze
      REMOTE_ADDR = 'REMOTE_ADDR'.freeze
      REMOTE_USER = 'REMOTE_USER'.freeze
      HTTP_VERSION = 'HTTP_VERSION'.freeze
      REMOTE_ADDRESS_ENV_KEY = "REMOTE_ADDR".freeze
      HTTP_HEADER_FILTER_EXCEPTIONS = %w(CONTENT_TYPE CONTENT_LENGTH).freeze
      TRANSACTION_ID = 'HTTP_SITEHUB_TRANSACTION_ID'.freeze
    end
  end
end