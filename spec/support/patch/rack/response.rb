module Rack
  class Response
    def cookies
      cookie_key_value_array.each_with_object({}) do |cookie_key_value, cookies|
        name_value_array = cookie_key_value.delete_at(0)
        name, value = *name_value_array
        data = cookie_key_value.collect { |pair| [pair[0].to_sym, pair[1]] }.to_h
        cookies[name] = { value: value }.merge(data)
        cookies
      end
    end

    def cookie_key_value_array
      header['Set-Cookie'].lines.collect { |line| line.scan(%r{([\.\w]+)=([\.\w/]+)}) }
    end
  end
end
