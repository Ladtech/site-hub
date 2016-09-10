describe 'config server' do
  include_context :integration
  include_context :sitehub_json

  let(:config) do
    {
      proxies: [
        {
          sitehub_cookie_name: 'custom_name',
          sitehub_cookie_path: '/custom/path',
          path: '%r{/regex(.*)}',
          default: DOWNSTREAM_URL
        }
      ]
    }
  end

  let(:downstream_response) { 'downstream response' }

  before do
    stub_request(:get, CONFIG_SERVER_URL).and_return(body: config.to_json)
    stub_request(:get, DOWNSTREAM_URL).and_return(body: downstream_response)
  end

  let(:app) do
    sitehub = sitehub do
      config_server(CONFIG_SERVER_URL, caching_options: { expires_in: 1 })
    end

    Async::Middleware.new(sitehub)
  end

  context 'from_json' do
    it 'reads cookie path from config' do
      get('/regex123')

      expect(app.last_response.cookies['custom_name'][:path]).to eq('/custom/path')
    end
  end

  it 'path as regex' do
    get('/regex123')

    expect(app.last_response.body).to eq([downstream_response])
  end
end
