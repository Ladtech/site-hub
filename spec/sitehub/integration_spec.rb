require 'async/middleware'
require 'stringio'
shared_context :site_hub do
  let(:downstream_url) { 'http://localhost:12345' }
  let(:experiment1_url) {"#{downstream_url}/experiment1"}
  let(:experiment2_url) {"#{downstream_url}/experiment2"}

  before do
    WebMock.enable!
    stub_request(:get, experiment1_url).to_return(body: 'hello')
    stub_request(:get, experiment2_url).to_return(body: 'experiment1_body')
  end

  let(:builder) do
    SiteHub::Builder.new.tap do |builder|
      builder.access_logger StringIO.new
      builder.error_logger StringIO.new
      experiment1_url = experiment1_url()
      experiment2_url = experiment2_url()

      builder.proxy '/endpoint' do
        split(label: :experiment1, percentage: 100) do
          split percentage: 100, label: 'variant1', url: experiment1_url
        end

        split(label: :experiment2, percentage: 0) do
          split percentage: 100, label: 'variant2', url: experiment2_url
        end
      end
    end
  end

  let(:rack_application) do
    builder.build
  end

  let :app do
    rack_application
  end
end

describe 'proxying calls' do
  include_context :site_hub


  let(:app) { Async::Middleware.new(rack_application) }
  describe 'supported HTTP verbs' do
    %i(get post put delete).each do |verb|
      it 'forwards the downstream' do
        stub_request(verb, experiment1_url).to_return(body: 'hello')
        send(verb, '/endpoint')
        expect(app.last_response.body).to eq(['hello'])
      end
    end
  end

  describe 'route affinity' do
    context 'requested route cookie not present' do
      it 'drops a cookie to keep you on the same path' do
        stub_request(:get, downstream_url).to_return(body: 'hello')
        get('/endpoint')
        expect(app.last_response.cookies[SiteHub::RECORDED_ROUTES_COOKIE][:value]).to eq('experiment1|variant1')
      end
    end

    context 'requested route cookie present' do
      it 'proxies to the preselected route' do
        get('/endpoint', {}, {'HTTP_COOKIE' => "#{SiteHub::RECORDED_ROUTES_COOKIE}=experiment2|variant1"})
        expect(app.last_response.body).to eq(['experiment1_body'])
      end
    end

  end
end
