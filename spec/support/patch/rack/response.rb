class Rack::Response
  def cookies
    cookies = {}
    header['Set-Cookie'].lines.collect { |line| line.scan(/([\.\w]+)=([\.\w\/]+)/) }.each do |cookie_definition_array|
      name_value_array = cookie_definition_array.delete_at(0)
      name = name_value_array.first
      value = name_value_array.last
      data = cookie_definition_array.collect { |pair| [pair[0].to_sym, pair[1]] }.to_h
      cookies[name] = {value: value}.merge(data)
    end
    cookies
  end

  def cookies_as_hash
    cookies = {}
    header['Set-Cookie'].lines.collect { |line| line.scan(/([\.\w]+)=([\.\w]+)/) }.each do |cookie_definition_array|
      name_value_array = cookie_definition_array.delete_at(0)
      name = name_value_array.first
      value = name_value_array.last
      data = cookie_definition_array.collect { |pair| [pair[0].to_sym, pair[1]] }.to_h
      cookies[name] = {value: value}.merge(data)
    end
    cookies
  end
end