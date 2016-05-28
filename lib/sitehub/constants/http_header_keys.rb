class SiteHub
  module Constants
    module HttpHeaderKeys
      PROXY_CONNECTION = 'proxy-connection'.freeze
      LOCATION_HEADER = 'location'.freeze
      HOST_HEADER = 'host'.freeze
      X_FORWARDED_HOST_HEADER = 'x-forwarded-host'.freeze
      X_FORWARDED_FOR_HEADER = 'x-forwarded-for'.freeze
      CONNECTION_HEADER = 'connection'.freeze
      KEEP_ALIVE = 'keep-alive'.freeze
      PROXY_AUTHENTICATE = 'proxy-authenticate'.freeze
      PROXY_AUTHORIZATION = 'proxy-authorization'.freeze
      TE = 'te'.freeze
      TRAILERS = 'trailers'.freeze
      TRANSFER_ENCODING = 'transfer-encoding'.freeze
      CONTENT_ENCODING = 'content-encoding'.freeze
      SET_COOKIE = 'Set-Cookie'.freeze
      CONTENT_LENGTH = 'Content-Length'.freeze
    end
  end
end
