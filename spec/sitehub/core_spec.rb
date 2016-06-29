class SiteHub
  describe Core do
    include_context :middleware_test

    let(:config) do
      {
          proxies: [
              {
                  path: '/route_1',
                  routes: [
                      {
                          label: :label_1,
                          url: 'http://lvl-up.uk/'
                      }
                  ]
              }
          ]
      }
    end

    describe '::from_hash' do

      context 'invalid config' do
        context 'proxies missing' do
          it 'throws and error' do
            expect { described_class.from_hash({}) }.to raise_error(ConfigError)
          end
        end
      end


      subject(:expected) do
        described_class.new do
          proxy '/route_1' do
            route label: :label_1, url: 'http://lvl-up.uk/'
          end
        end
      end

      context 'proxies defined' do
        it 'creates them' do
          expect(described_class.from_hash(config)).to eq(expected)
        end
      end

      context 'sitehub_cookie_name' do
        subject(:expected) do
          described_class.new do
            sitehub_cookie_name 'custom_name'
            proxy('/route_1') { route label: :label_1, url: 'http://lvl-up.uk/' }
          end
        end

        it 'sets it' do
          core = described_class.from_hash(config.merge(sitehub_cookie_name: 'custom_name'))

          expect(core.sitehub_cookie_name).to eq(expected.sitehub_cookie_name)
          expect(core.forward_proxies['/route_1'].sitehub_cookie_name).to eq(expected.sitehub_cookie_name)
        end
      end

      context 'reverse_proxies' do
        before do
          config[:reverse_proxies] = [{downstream_url: :url, path: :path}]
        end
        let(:expected) do
          described_class.from_hash(config)
        end

        it 'sets them' do
          expect(expected.reverse_proxies).to eq({url: :path})
        end
      end
    end

    subject do
      described_class.new
    end

    describe '#build' do
      context 'reverse proxy' do
        it 'adds a reverse proxy' do
          expect(subject.build).to be_using(Middleware::ReverseProxy)
        end

        it 'uses configured reverse proxy directives' do
          subject.reverse_proxy(downstream_url: :upstream_path.to_s)
          reverse_proxy = find_middleware(subject.build, Middleware::ReverseProxy)

          expect(reverse_proxy.path_directives).to eq(LocationRewriters.new(downstream_url: :upstream_path.to_s))
        end
      end
    end
    describe '#reverse_proxy' do
      it 'registers a reverse proxy' do
        subject.reverse_proxy(downstream_url: :upstream_path)
        expect(subject.reverse_proxies).to eq(downstream_url: :upstream_path)
      end
    end

    describe '#proxy' do
      context 'no version explicitly defined' do
        subject do
          described_class.new do
            proxy '/app1' => :endpoint
          end
        end

        it 'the defined route is used 100% of the time' do
          expected_proxy = ForwardProxyBuilder.new(mapped_path: '/app1',
                                                   sitehub_cookie_name: RECORDED_ROUTES_COOKIE).tap do |route|
            route.default(url: :endpoint)
          end
          expect(subject.forward_proxies['/app1']).to eq(expected_proxy)
        end
      end

      context 'custom route defined' do
        subject do
          described_class.new do
            proxy('/app') do
              split url: :endpoint, label: :label, percentage: 100
            end
          end
        end

        it 'passes the block to the route constructor' do
          expected_route = ForwardProxyBuilder.new(mapped_path: '/app',
                                                   sitehub_cookie_name: RECORDED_ROUTES_COOKIE).tap do |route|
            route.split url: :endpoint, percentage: 100, label: :label
          end

          expect(subject.forward_proxies['/app'].endpoints).to eq(expected_route.endpoints)
        end
      end
    end
  end
end
