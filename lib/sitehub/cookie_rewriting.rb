require 'sitehub/cookie'
require 'sitehub/constants'
class SiteHub
  module CookieRewriting
    ENDING_WITH_NEWLINE = /#{NEW_LINE}$/

    def rewrite_cookies(headers, substitute_domain:)
      cookies_hash = cookies_string_as_hash(headers[Constants::HttpHeaderKeys::SET_COOKIE])

      cookies_hash.values.each do |cookie|
        domain_attribute = cookie.find(:domain) || next
        value = domain_attribute.value
        domain_attribute.value = substitute_domain.dup
        domain_attribute.value.prepend(FULL_STOP) if value.start_with?(FULL_STOP)
      end
      headers[HttpHeaders::SET_COOKIE] = cookies_hash_to_string(cookies_hash)
    end

    def cookies_hash_to_string(cookies_hash)
      cookies_hash.values.inject(EMPTY_STRING.dup) do |cookie_string, cookie|
        cookie_string << "#{cookie}#{NEW_LINE}"
      end.sub(ENDING_WITH_NEWLINE, EMPTY_STRING)
    end

    def cookies_string_as_hash(cookie_string)
      cookie_string.lines.each_with_object({}) do |cookie_line, cookies|
        cookie = SiteHub::Cookie.new(cookie_line)
        cookies[cookie.name] = cookie
        cookies
      end
    end
  end
end
