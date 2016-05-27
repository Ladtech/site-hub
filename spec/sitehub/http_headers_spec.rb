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

    describe '#sanitise_headers' do
      context 'port 80 present in url' do
        it 'removes the port' do
          headers_hyphonised['location'] = 'http://mysite.com:80/redirect_endpoint'
          expect(subject.sanitise_headers(headers_hyphonised)['location']).to eq('http://mysite.com/redirect_endpoint')
        end
      end

      context 'port 443 present in url' do
        it 'removes the port' do
          headers_hyphonised['location'] = 'http://mysite.com:443/redirect_endpoint'
          expect(subject.sanitise_headers(headers_hyphonised)['location']).to eq('http://mysite.com/redirect_endpoint')
        end
      end

      describe 'treatment of headers according to RFC2616: 13.5.1 and RFC2616: 14.10' do
        context 'prohibitted headers hyphonised' do
          it 'filters them out' do
            sanatised_headers = subject.sanitise_headers(headers_hyphonised)
            expect(sanatised_headers.empty?).to eq(true)
          end
        end

        context 'prohibitted headers underscored' do
          it 'filters them out' do
            sanatised_headers = subject.sanitise_headers(headers_underscored)
            expect(sanatised_headers.empty?).to eq(true)
          end
        end

        it 'filters out connections' do
          headers = subject.sanitise_headers('connection' => 'a, b',
                                             'a' => 'value_a',
                                             'b' => 'value_b', 'c' => 'value_c')

          expect(headers).to eq('c' => 'value_c')
        end
      end
    end
  end
end
