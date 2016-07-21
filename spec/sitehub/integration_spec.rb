require 'async/middleware'
require 'stringio'
shared_context :site_hub do
  let(:downstream_url) { 'http://localhost:12345' }
  let(:experiment1_url) { "#{downstream_url}/experiment1" }
  let(:experiment2_url) { "#{downstream_url}/experiment2" }

  before do
    WebMock.enable!
    stub_request(:get, experiment1_url).to_return(body: 'experiment1_body')
    stub_request(:get, experiment2_url).to_return(body: 'experiment2_body')
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
          split percentage: 0, label: 'variant1', url: experiment2_url
          split percentage: 100, label: 'variant2', url: experiment2_url
        end
      end
    end
  end

  let(:rack_application) do
    builder.build
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
        get('/endpoint')
        expect(app.last_response.cookies[SiteHub::RECORDED_ROUTES_COOKIE][:value]).to eq('experiment1|variant1')
      end
    end

    context 'requested route cookie present' do
      it 'proxies to the preselected route' do
        get('/endpoint', {}, 'HTTP_COOKIE' => "#{SiteHub::RECORDED_ROUTES_COOKIE}=experiment2|variant1")
        expect(app.last_response.body).to eq(['experiment2_body'])

        expect(app.last_response.cookies[SiteHub::RECORDED_ROUTES_COOKIE][:value]).to eq('experiment2|variant1')
      end
    end
  end

  describe 'middleware' do

    include_context :middleware_test

    let(:app) { Async::Middleware.new(rack_application) }

    def middleware name
      create_middleware.tap do |clazz|
        clazz.class_eval do
          define_method :call do |env|

            callback = env['async.callback'] || env['async.orig_callback']
            env['async.orig_callback'] = env['async.callback'] = proc do |status, headers, body|
              body = body.body.join if body.is_a?(Rack::BodyProxy)

              callback.call(status, headers, "#{name}, #{body}")
            end
            @app.call(env)
          end
        end
      end
    end

    before do
      stub_request(:get, downstream_url).to_return(body: 'hello')
    end

    context 'middleware added to top level' do
      let(:builder) do
        middleware = middleware(:middleware1)
        downstream_url = downstream_url()

        SiteHub::Builder.new do
          access_logger StringIO.new
          use middleware
          proxy '/1' => downstream_url
          proxy '/2' => downstream_url
        end
      end

      it 'adds it to each route' do
        get('/1')
        expect(app.last_response.body.join).to eq('middleware1, hello')
        get('/2')
        expect(app.last_response.body.join).to eq('middleware1, hello')
      end
    end

    context 'middleware added to specific route' do
      let(:builder) do
        middleware = middleware(:middleware1)
        downstream_url = downstream_url()

        SiteHub::Builder.new do
          access_logger StringIO.new
          proxy '/1' do
            use middleware
            route label: :with_middleware, url: downstream_url
          end
          proxy '/2' => downstream_url
        end
      end

      it 'adds it to that route only' do
        get('/1')
        expect(app.last_response.body.join).to eq('middleware1, hello')
        get('/2')
        expect(app.last_response.body.join).to eq('hello')
      end
    end

    context 'base inherited middleware' do
      let(:builder) do
        middleware1 = middleware(:middleware1)
        middleware2 = middleware(:middleware2)
        downstream_url = downstream_url()

        SiteHub::Builder.new do
          access_logger StringIO.new
          use middleware1
          proxy '/1' do
            use middleware2
            route label: :with_middleware, url: downstream_url
          end
          proxy '/2' => downstream_url
        end
      end

      it 'adds it to that route only' do
        get('/1')
        expect(app.last_response.body.join).to eq('middleware1, middleware2, hello')
        get('/2')
        expect(app.last_response.body.join).to eq('middleware1, hello')
      end
    end

    context 'nested inherited middleware' do
      let(:builder) do
        middleware1 = middleware(:middleware1)
        middleware2 = middleware(:middleware2)
        downstream_url = downstream_url()

        SiteHub::Builder.new do
          access_logger StringIO.new

          proxy '/1' do
            split percentage: 100, label: :experiment1 do
              use middleware1
              split percentage: 100, label: :with_middleware do
                use middleware2
                split percentage: 100, label: :with_nested_middleware, url: downstream_url
              end
            end
          end
          proxy '/2' => downstream_url
        end
      end

      it 'adds it to that route only' do
        get('/1')
        expect(app.last_response.body.join).to eq('middleware1, middleware2, hello')
        get('/2')
        expect(app.last_response.body.join).to eq('hello')
      end
    end
  end
end
