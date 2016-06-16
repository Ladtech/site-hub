shared_context :rack_headers do
  def to_rack_headers(hash)
    hash.each_with_object({}) do |key_value, converted_headers|
      env_key = key_value[0].upcase.tr('-', '_')
      env_key = 'HTTP_' + env_key unless 'CONTENT_TYPE' == env_key
      converted_headers[env_key] = key_value[1]
    end
  end
end
