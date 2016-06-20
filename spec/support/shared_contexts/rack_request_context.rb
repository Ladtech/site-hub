shared_context :rack_request do
  def format_as_rack_header_name(key)
    rack_key = key.upcase.tr('-', '_')
    %w(CONTENT_TYPE CONTENT_LENGTH REMOTE_ADDR).include?(key) ? rack_key : "HTTP_#{rack_key}"
  end

  def format_http_to_rack_headers(hash)
    hash.each_with_object({}) do |key_value, converted_headers|
      env_key = format_as_rack_header_name(key_value[0])
      converted_headers[env_key] = key_value[1]
    end
  end

  def env_for(path: '/', method: :get, params_or_body: {}, env: {})
    env = env.merge(method: method, params: params_or_body)
    Rack::Test::Session.new(nil).send(:env_for, path, env)
  end
end
