require 'sitehub/constants/http_header_keys'
require 'sitehub/constants/rack_http_header_keys'

class SiteHub
  REQUEST_MAPPING = 'sitehub.request_mapping'.freeze
  RESPONSE = 'sitehub.response'.freeze
  ASYNC_CALLBACK = 'async.callback'.freeze
  RECORDED_ROUTES_COOKIE = 'sitehub.recorded_route'.freeze
  ERRORS = 'sitehub.errors'.freeze
  TIME_STAMP_FORMAT = '%d/%b/%Y:%H:%M:%S %z'.freeze
  EMPTY_STRING = ''.freeze
  UNDERSCORE = '_'.freeze
  SEMICOLON = ';'.freeze
  SPACE = ' '.freeze
  SEMICOLON_WITH_SPACE = "#{SEMICOLON}#{SPACE}".freeze
  COMMA_WITH_SPACE = ', '.freeze

  HYPHEN = '-'.freeze
  QUESTION_MARK = '?'.freeze
  EQUALS_SIGN = '='.freeze
  FULL_STOP = '.'.freeze
  NEW_LINE = "\n".freeze
end
