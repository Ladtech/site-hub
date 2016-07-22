require 'stringio'

describe 'route affinity' do

  let(:downstream_url) { 'http://localhost:12345' }
  let(:experiment1_url) { "#{downstream_url}/experiment1" }
  let(:experiment2_url) { "#{downstream_url}/experiment2" }

  let(:experiment_body_1){'experiment1_body'}
  let(:experiment_body_2){'experiment2_body'}

  before do
    WebMock.enable!
  end

  let(:app) do
    experiment1_url = experiment1_url()
    experiment2_url = experiment2_url()

    sitehub = SiteHub.build do
      access_logger StringIO.new
      error_logger StringIO.new

      proxy '/endpoint' do
        split(label: :experiment1, percentage: 100) do
          split percentage: 100, label: 'variant1', url: experiment1_url
        end

        split(label: :experiment2, percentage: 0) do
          split percentage: 0, label: 'variant1', url: experiment2_url
          split percentage: 100, label: 'variant2', url: :should_not_be_called
        end
      end
    end
    Async::Middleware.new(sitehub)

  end

  context 'requested route cookie not present' do
    it 'drops a cookie to keep you on the same path' do
      stub_request(:get, experiment1_url).to_return(body: experiment_body_1)
      get('/endpoint')
      expect(app.last_response.body).to eq([experiment_body_1])
      expect(app.last_response.cookies[SiteHub::RECORDED_ROUTES_COOKIE][:value]).to eq('experiment1|variant1')
    end
  end

  context 'requested route cookie present' do
    it 'proxies to the preselected route' do
      stub_request(:get, experiment2_url).to_return(body: experiment_body_2)

      get('/endpoint', {}, 'HTTP_COOKIE' => "#{SiteHub::RECORDED_ROUTES_COOKIE}=experiment2|variant1")
      expect(app.last_response.body).to eq([experiment_body_2])
      expect(app.last_response.cookies[SiteHub::RECORDED_ROUTES_COOKIE][:value]).to eq('experiment2|variant1')
    end
  end
end

