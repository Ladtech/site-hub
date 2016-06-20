shared_context :http_proxy_rules do
  let(:hop_header_1) { 'hop-header-1' }
  let(:hop_header_2) { 'hop-header-2' }

  let(:prohibited_headers) do
    { 'connection' => [hop_header_1, hop_header_2].join(','),
      'keep-alive' => 'something',
      'proxy-authenticate' => 'something',
      'proxy-authorization' => 'something',
      'te' => 'something',
      'trailers' => 'something',
      'transfer-encoding' => 'something',
      'content-encoding' => 'something',
      'proxy-connection' => 'something',
      hop_header_1 => 'value',
      hop_header_2 => 'value' }
  end

  RSpec::Matchers.define :have_prohibitted_headers do
    match do |http_headers|
      http_headers.any? do |header_name, _value|
        prohibited_headers.key?(header_name.downcase)
      end
    end
  end

  RSpec::Matchers.define :include_headers do |*expected|
    match do |http_headers|
      actual_headers = http_headers.keys.collect(&:downcase)

      expected.collect(&:to_s).all? do |header_name|
        actual_headers.include?(header_name.downcase)
      end
    end
  end
end
