# rubocop:disable Metrics/ClassLength
require 'sitehub/builder'

class SiteHub
  describe Builder do
    include_context :middleware_test

    subject do
      described_class.new do
        proxy '/app1' => :endpoint
      end
    end

    it 'supports middleware' do
      expect(subject).to be_kind_of(Middleware)
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
          expect(subject.forward_proxies.forward_proxies['/app1']).to eq(expected_proxy)
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
          expected_route = ForwardProxyBuilder.new(mapped_path: '/path').tap do |route|
            route.split url: :endpoint, percentage: 100, label: :label
          end

          expect(subject.forward_proxies.forward_proxies['/app'].endpoints).to eq(expected_route.endpoints)
        end
      end
    end

    describe '#access_logger' do
      it ' sets the logger' do
        subject.access_logger :access_logger
        sitehub = subject.build
        logger_middleware = find_middleware(sitehub, Logging::AccessLogger)
        expect(logger_middleware.logger).to eq(Logging::LogWrapper.new(:access_logger))
      end

      it 'defaults to STDOUT' do
        allow(::Logger).to receive(:new).and_return(:a_logger)
        expect(::Logger).to receive(:new).with(STDOUT).and_return(:stdout_logger)
        sitehub = subject.build
        logger_middleware = find_middleware(sitehub, Logging::AccessLogger)
        expect(logger_middleware.logger).to eq(Logging::LogWrapper.new(:stdout_logger))
      end
    end

    describe '#reverse_proxy' do
      it 'registers a reverse proxy' do
        subject.reverse_proxy(downstream_url: :upstream_path)
        expect(subject.reverse_proxies).to eq(downstream_url: :upstream_path)
      end
    end

    describe '#sitehub_cookie_name' do
      it 'defaults to sitehub.recorded_route' do
        expect(subject.sitehub_cookie_name).to eq(RECORDED_ROUTES_COOKIE)
      end

      it 'is passed to forward_proxy_builders' do
        subject.sitehub_cookie_name :expected_cookie_name
        proxy = subject.proxy '/app1' => :endpoint
        expect(proxy.sitehub_cookie_name).to eq(:expected_cookie_name)
      end
    end

    describe '#error_logger' do
      it 'sets the logger' do
        subject.error_logger :error_logger
        sitehub = subject.build
        logger_middleware = find_middleware(sitehub, SiteHub::Logging::ErrorLogger)
        expect(logger_middleware.logger).to eq(Logging::LogWrapper.new(:error_logger))
      end

      it 'defaults to STDERR' do
        allow(::Logger).to receive(:new).and_return(:a_logger)
        expect(::Logger).to receive(:new).with(STDERR).and_return(:stderr_logger)
        sitehub = subject.build
        logger_middleware = find_middleware(sitehub, SiteHub::Logging::ErrorLogger)
        expect(logger_middleware.logger).to eq(Logging::LogWrapper.new(:stderr_logger))
      end
    end

    describe '#build' do
      it 'initializes the forward_proxies' do
        expect(subject.forward_proxies).to receive(:init).and_call_original
        subject.build
      end

      context 'default middleware' do
        it 'adds TransactionId middleware to the sitehub' do
          expect(subject.build).to be_using(TransactionId)
        end

        it 'adds a forward proxies' do
          expect(subject.build).to be_using(ForwardProxies)
        end

        it 'adds a AccessLogger' do
          expect(subject.build).to be_using(Logging::AccessLogger)
        end

        it 'adds a ErrorLogger' do
          expect(subject.build).to be_using(Logging::ErrorLogger)
        end
        it 'adds a Rack FiberPool' do
          expect(subject.build).to be_using(Rack::FiberPool)
        end

        it 'adds a ErrorHandler' do
          expect(subject.build).to be_using(SiteHub::ErrorHandling)
        end

        context 'reverse proxy' do
          it 'adds a reverse proxy' do
            expect(subject.build).to be_using(ReverseProxy)
          end

          it 'uses configured reverse proxy directives' do
            subject.reverse_proxy(downstream_url: :upstream_path.to_s)
            reverse_proxy = find_middleware(subject.build, ReverseProxy)

            expect(reverse_proxy.path_directives).to eq(PathDirectives.new(downstream_url: :upstream_path.to_s))
          end
        end

        it 'adds them in the right order' do
          middleware_stack = collect_middleware(subject.build).collect(&:class)

          expected_middleware = [Rack::FiberPool,
                                 Logging::ErrorLogger,
                                 Logging::AccessLogger,
                                 SiteHub::ErrorHandling,
                                 TransactionId,
                                 ReverseProxy,
                                 ForwardProxies]

          expect(middleware_stack).to eq(expected_middleware)
        end
      end

      context 'middleware defined' do
        it 'wraps the sitehub with it' do
          subject.use middleware
          expect(subject.build).to be_using(middleware)
        end
      end

      context '#force_ssl' do
        context 'true' do
          subject do
            described_class.new do
              force_ssl
            end.build
          end

          it 'adds SslEnforcer Middleware to the sitehub at the top level' do
            expect(subject).to be_a(Rack::SslEnforcer)
          end

          context 'exclusions supplied' do
            subject do
              described_class.new do
                force_ssl except: :google
              end.build
            end
            it 'gives them to the ssl enforcer middleware' do
              exclusions = subject.instance_variable_get(:@options)[:except]
              expect(exclusions).to eq(:google)
            end
          end
        end

        context 'false' do
          it 'does not add SslEnforcer middleware' do
            sitehub = described_class.new.build

            expect(sitehub).to_not be_using(Rack::SslEnforcer)
          end
        end
      end
    end
  end
end
