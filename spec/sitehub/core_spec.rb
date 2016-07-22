class SiteHub
  describe Core do
    include_context :middleware_test
    include_context :sitehub_json

    describe '::from_hash' do
      subject(:core) { described_class.from_hash(sitehub_json) }

      subject(:expected) do
        described_class.new do
          sitehub_cookie_name 'custom_name'
          proxy('/route_1') { route label: :label_1, url: 'http://lvl-up.uk/' }
        end
      end

      context 'proxies missing' do
        it 'throws and error' do
          sitehub_json.delete(:proxies)
          expect { core }.to raise_error(ConfigError)
        end
      end

      context 'reverse_proxies missing' do
        it 'does not throw an error' do
          sitehub_json.delete(:reverse_proxies)
          expect { core }.to_not raise_error
        end
      end

      context 'proxies defined' do
        it 'creates them' do
          expect(core).to eq(expected)
        end
      end

      context 'sitehub_cookie_name' do
        it 'sets it' do
          sitehub_json[:sitehub_cookie_name] = 'custom_name'

          expect(core.sitehub_cookie_name).to eq(expected.sitehub_cookie_name)
          expect(core.mappings['/route_1'].sitehub_cookie_name).to eq(expected.sitehub_cookie_name)
        end
      end

      context 'reverse_proxies' do
        it 'sets them' do
          sitehub_json[:reverse_proxies] = [{ downstream_url: :url, path: :path }]
          expect(core.reverse_proxies).to eq(url: :path)
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
      let(:expected_route) do
        RouteCandidates.new(sitehub_cookie_name: RECORDED_ROUTES_COOKIE,
                            mapped_path: '/app')
      end

      context 'string as parameters' do
        it 'treats it as the mapped path' do
          expect_any_instance_of(Middleware::Mappings)
            .to receive(:add_route)
            .with(url: nil, mapped_path: '/app').and_call_original
          subject.proxy('/app')
        end
      end

      context 'hash as parameter' do
        it 'treats the key as the mapped path and the value as downstream url' do
          expect_any_instance_of(Middleware::Mappings)
            .to receive(:add_route)
            .with(url: :downstream_url, mapped_path: '/app').and_call_original
          subject.proxy('/app' => :downstream_url)
        end
      end

      context 'block passed in' do
        it 'uses the block when creating the proxy' do
          proc = proc {}

          expect_any_instance_of(Middleware::Mappings).to receive(:add_route) do |*_args, &block|
            expect(block).to be(proc)
          end

          subject.proxy('/app' => :downstream_url, &proc)
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
          expected_route.split url: :endpoint, percentage: 100, label: :label
          expect(subject.mappings['/app'].routes).to eq(expected_route.routes)
        end
      end
    end
  end
end
