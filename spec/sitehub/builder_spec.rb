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

    describe '#access_logger' do
      it ' sets the logger' do
        subject.access_logger :access_logger
        sitehub = subject.build
        logger_middleware = find_middleware(sitehub, Middleware::Logging::AccessLogger)
        expect(logger_middleware.logger).to eq(Middleware::Logging::LogWrapper.new(:access_logger))
      end

      it 'defaults to STDOUT' do
        allow(::Logger).to receive(:new).and_return(:a_logger)
        expect(::Logger).to receive(:new).with(STDOUT).and_return(:stdout_logger)
        sitehub = subject.build
        logger_middleware = find_middleware(sitehub, Middleware::Logging::AccessLogger)
        expect(logger_middleware.logger).to eq(Middleware::Logging::LogWrapper.new(:stdout_logger))
      end
    end

    describe '#sitehub_cookie_name' do
      it 'defaults to sitehub.recorded_route' do
        expect(subject.sitehub_cookie_name).to eq(RECORDED_ROUTES_COOKIE)
      end

      context 'forward_proxies' do
        subject do
          described_class.new do
            sitehub_cookie_name :expected_cookie_name
            proxy '/app1' => :endpoint
          end
        end

        it 'forwards it' do
          proxy = subject.proxy '/app1' => :endpoint
          expect(proxy.sitehub_cookie_name).to eq(:expected_cookie_name)
        end
      end
    end

    describe '#error_logger' do
      it 'sets the logger' do
        subject.error_logger :error_logger
        sitehub = subject.build
        logger_middleware = find_middleware(sitehub, Middleware::Logging::ErrorLogger)
        expect(logger_middleware.logger).to eq(Middleware::Logging::LogWrapper.new(:error_logger))
      end

      it 'defaults to STDERR' do
        allow(::Logger).to receive(:new).and_return(:a_logger)
        expect(::Logger).to receive(:new).with(STDERR).and_return(:stderr_logger)
        sitehub = subject.build
        logger_middleware = find_middleware(sitehub, Middleware::Logging::ErrorLogger)
        expect(logger_middleware.logger).to eq(Middleware::Logging::LogWrapper.new(:stderr_logger))
      end
    end

    describe '#method_missing' do
      context 'method not found' do
        it 'throws an error' do
          expect { subject.invalid_method }.to raise_error(NoMethodError)
        end
      end
    end

    describe '#method_missing' do
      context 'method not found' do
        it 'throws an error' do
          expect { subject.invalid_method }.to raise_error(NoMethodError)
        end
      end
    end

    describe '#respond_to?' do
      context 'method exists on core' do
        it 'returns true' do
          expect(subject.respond_to?(:proxy)).to eq(true)
        end
      end

      context 'method exists on builder' do
        it 'returns true' do
          expect(subject.respond_to?(:access_logger)).to eq(true)
        end
      end

      context 'method does not exist' do
        it 'returns false' do
          expect(subject.respond_to?(:missing)).to eq(false)
        end
      end
    end

    describe '#build' do
      context 'default middleware' do
        it 'returns a fiber pool' do
          expect(subject.build).to be_a(Rack::FiberPool)
        end
        it 'adds TransactionId middleware to the sitehub' do
          expect(subject.build).to be_using(Middleware::TransactionId)
        end

        context 'forward proxies' do
          subject do
            described_class.new do
              sitehub_cookie_name :custom_cookie_name
              proxy '/app1' => :endpoint
            end
          end

          it 'adds a forward proxies' do
            expect(subject.build).to be_using(Middleware::CandidateRouteMappings)
          end

          it 'configures it with the sitehub_cookie_name' do
            forward_proxies = find_middleware(subject.build, Middleware::CandidateRouteMappings)
            expect(forward_proxies.sitehub_cookie_name).to eq(:custom_cookie_name)
          end
        end

        it 'adds a AccessLogger' do
          expect(subject.build).to be_using(Middleware::Logging::AccessLogger)
        end

        it 'adds a ErrorLogger' do
          expect(subject.build).to be_using(Middleware::Logging::ErrorLogger)
        end

        it 'adds a ErrorHandler' do
        end

        context 'config server specified' do
          before do
            subject.config_server :server_url
          end

          it 'adds a ConfigLoader' do
            expect(subject.build).to be_using(Middleware::ConfigLoader)
          end

          it 'adds it just before the reverse proxy' do
            middleware_stack = collect_middleware(subject.build).collect(&:class)

            expected_middleware = [Middleware::Logging::ErrorLogger,
                                   Middleware::Logging::AccessLogger,
                                   Middleware::ErrorHandling,
                                   Middleware::TransactionId,
                                   Middleware::ConfigLoader]

            expect(middleware_stack).to eq(expected_middleware)
          end
        end

        it 'adds them in the right order' do
          middleware_stack = collect_middleware(subject.build).collect(&:class)

          expected_middleware = [Middleware::Logging::ErrorLogger,
                                 Middleware::Logging::AccessLogger,
                                 Middleware::ErrorHandling,
                                 Middleware::TransactionId,
                                 Middleware::ReverseProxy,
                                 Middleware::CandidateRouteMappings]

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
