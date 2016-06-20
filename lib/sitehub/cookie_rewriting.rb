require 'sitehub/cookie'
require 'sitehub/constants'
class SiteHub
  # TODO: - change in to object and remove .reek exclusions for UtilityFunction
  module CookieRewriting
    ENDING_WITH_NEWLINE = /#{NEW_LINE}$/

    def rewrite_cookies(headers, substitute_domain:)
      cookies_hash = cookies_string_as_hash(headers[Constants::HttpHeaderKeys::SET_COOKIE])

      cookies_hash.values.each do |cookie|
        domain_attribute = cookie.find(:domain) || next
        update_domain(domain_attribute, substitute_domain)
      end
      headers[Constants::HttpHeaderKeys::SET_COOKIE] = cookies_hash_to_string(cookies_hash)
    end

    def update_domain(domain_attribute, substitute_domain)
      substitute = substitute_domain.dup
      if domain_attribute.value.start_with?(FULL_STOP)
        domain_attribute.update(substitute.prepend(FULL_STOP))
      else
        domain_attribute.update(substitute)
      end
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
      end
    end
  end
end
