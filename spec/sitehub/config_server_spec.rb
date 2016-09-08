require 'sitehub/config_server'

class SiteHub
  describe ConfigServer do
    include_context :sitehub_json

    let(:server_url) { 'http://www.server.url' }
    let(:config) { { config: 'value' } }

    subject do
      described_class.new(server_url)
    end

    describe '#get' do
      context 'non 200 returned' do
        it 'raises an error' do
          bad_response_code = 500
          stub_request(:get, server_url).to_return(body: config.to_json, status: bad_response_code)
          expected_message = described_class::NON_200_RESPONSE_MSG % bad_response_code
          expect { subject.get }.to raise_error(described_class::Error, expected_message)
        end
      end

      context 'exception thrown in client' do
        it 'raises an error' do
          error_msg = 'error from library'
          expect_any_instance_of(Faraday::Connection).to receive(:get).and_raise(Faraday::ConnectionFailed, error_msg)
          expected_message = described_class::UNABLE_TO_CONTACT_SERVER_MSG % error_msg
          expect { subject.get }.to raise_error(described_class::Error, expected_message)
        end
      end

      context 'malformed json returned' do
        it 'returns an error' do
          bad_json = 'bad json'
          stub_request(:get, server_url).to_return(body: bad_json)
          expected_message = described_class::BAD_JSON_MSG % bad_json
          expect { subject.get }.to raise_error(described_class::Error, expected_message)
        end
      end

      it 'returns config as a hash' do
        stub_request(:get, server_url).to_return(body: config.to_json)
        expect(subject.get).to eq(config)
      end
    end
  end
end
