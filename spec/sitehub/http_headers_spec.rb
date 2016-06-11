require 'sitehub/http_headers'
class SiteHub
  describe HttpHeaders do
    subject do
      Object.new.tap do |o|
        o.extend(described_class)
      end
    end

    let(:headers_underscored) do
      { 'CONNECTION' => 'close',
        'KEEP_ALIVE' => 'something',
        'PROXY_AUTHENTICATE' => 'something',
        'PROXY_AUTHORIZATION' => 'something',
        'TE' => 'something',
        'TRAILERS' => 'something',
        'TRANSFER_ENCODING' => 'something',
        'CONTENT_ENCODING' => 'something',
        'PROXY_CONNECTION' => 'something' }
    end

    let(:headers_hyphonised) do
      {}.tap do |hash|
        headers_underscored.each do |key, value|
          hash[key.tr('_', '-')] = value
        end
      end
    end
  end
end
