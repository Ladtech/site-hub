describe 'middleware' do
  include_context :middleware_test

  let(:downstream_url) { 'http://localhost:12345' }
  let(:experiment1_url) { "#{downstream_url}/experiment1" }
  let(:experiment2_url) { "#{downstream_url}/experiment2" }

  def middleware(name)
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

  let(:app) { Async::Middleware.new(builder) }

  before do
    WebMock.enable!
    stub_request(:get, downstream_url).to_return(body: 'hello')
  end

  context 'middleware added to top level' do
    let(:builder) do
      middleware = middleware(:middleware1)
      downstream_url = downstream_url()

      SiteHub.build do
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

      SiteHub.build do
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

      SiteHub.build do
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

      SiteHub.build do
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
