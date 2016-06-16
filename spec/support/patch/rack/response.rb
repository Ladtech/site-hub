module Rack
  class Response
    def cookies
      cookie_key_value_array.each_with_object({}) do |cookie_data_hash, cookies|
        name, value = *cookie_data_hash.delete_at(0)
        data = cookie_data(cookie_data_hash)
        cookies[name] = { value: value }.merge(data)
      end
    end

    def cookie_data(cookie_data_hash)
      cookie_data_hash.collect { |key, assigned_data| [key.to_sym, assigned_data] }.to_h
    end

    def cookie_key_value_array
      header['Set-Cookie'].lines.collect { |line| line.scan(%r{([\.\w]+)=([\.\w/]+)}) }
    end
  end
end
