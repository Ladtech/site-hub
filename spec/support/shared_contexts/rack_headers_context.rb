shared_context :rack_headers do
  def to_rack_headers(hash)
    converted_headers = {}

    hash.each do |name, value|
      env_key = name.upcase.tr('-', '_')
      env_key = 'HTTP_' + env_key unless 'CONTENT_TYPE' == env_key
      converted_headers[env_key] = value
    end

    converted_headers
  end
end
