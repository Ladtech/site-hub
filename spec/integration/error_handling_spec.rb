require 'stringio'
describe 'error handling' do
  context 'using config server' do
    include_context :integration
    include_context :sitehub_json

    let(:config) do
      { proxies: [
        {
          path: '/',
          default: DOWNSTREAM_URL
        }
      ] }
    end

    let(:downstream_response) { 'downstream response' }

    before do
      stub_request(:get, DOWNSTREAM_URL).and_return(body: downstream_response)
    end
    let(:app) do
      sitehub = sitehub do
        config_server(CONFIG_SERVER_URL, caching_options: { expires_in: 1 })
      end
      Async::Middleware.new(sitehub)
    end

    it 'reads the config for routing' do
      stub_request(:get, CONFIG_SERVER_URL).and_return(body: config.to_json)
      get('/')
      expect(app.last_response.body).to eq([downstream_response])
    end

    context 'config server is broken' do
      let(:bad_status) { 500 }
      context 'config has not been loaded' do
        it 'returns an error' do
          stub_request(:get, CONFIG_SERVER_URL).and_return(status: 500)
          get('/')
          expect(app.last_response.status).to eq(500)
        end

        it 'logs an error' do
          bad_status = 500
          stub_request(:get, CONFIG_SERVER_URL).and_return(status: bad_status)
          get('/')
          expect(ERROR_LOGGER.string).to include(SiteHub::ConfigServer::NON_200_RESPONSE_MSG % bad_status)
        end
      end

      context 'config has been correctly loaded once' do
        before do
          stub_request(:get, CONFIG_SERVER_URL).and_return(body: config.to_json)
          get('/')

          stub_request(:get, CONFIG_SERVER_URL).and_return(status: bad_status)
        end

        it 'uses the old config' do
          Timecop.travel(1)
          get('/')

          expect(app.last_response.body).to eq([downstream_response])
        end

        it 'logs the failure to read config' do
          get('/')
          expect(ERROR_LOGGER.string).to include(SiteHub::ConfigServer::NON_200_RESPONSE_MSG % bad_status)
        end
      end
    end
  end
end
