class SiteHub
  describe HttpHeaders do
    include_context :http_proxy_rules
    include_context :rack_request

    describe '::from_rack_env' do
      let(:http_header_filter_exceptions) { Constants::RackHttpHeaderKeys::HTTP_HEADER_FILTER_EXCEPTIONS }

      it 'removes rack specific headers' do
        expect(described_class.from_rack_env('rack.specific' => 'value')).to be_empty
      end

      it 'leaves exceptions behind' do
        rack_headers = http_header_filter_exceptions.each_with_object({}) do |rack_header, hash|
          hash[rack_header] = 'value'
        end

        expected_keys = http_header_filter_exceptions.collect { |key| key.to_s.downcase.tr('_', '-') }

        expect(described_class.from_rack_env(rack_headers).keys).to eq(expected_keys)
      end

      it 'removes any entries with nil values' do
        expect(described_class.from_rack_env('HTTP_RACK_FORMATTED' => nil)).to be_empty
      end

      it 'formats keys as http compatible' do
        expected_http_format = { 'rack-formatted' => :value }
        expect(described_class.from_rack_env('HTTP_RACK_FORMATTED' => :value)).to eq(expected_http_format)
      end

      it 'returns a HttpHeaders object' do
        expect(described_class.from_rack_env({})).to be_a(described_class)
      end
    end

    it_behaves_like 'prohibited_header_filter' do
      subject do
        described_class.new(prohibited_headers.merge(permitted_header => 'value'))
      end
    end

    describe '#initialize' do
      it 'downcases all keys' do
        expected_http_format = { 'upper-case' => :value }
        expect(described_class.new('UPPER-CASE' => :value)).to eq(expected_http_format)
      end
    end
  end
end
