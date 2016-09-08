require 'timecop'
class SiteHub
  module Middleware
    describe ConfigLoader do
      let(:server_url) { 'http://www.server.url' }

      let(:config) do
        {
          proxies: [
            {
              path: '/route_1',
              sitehub_cookie_name: 'sitehub.recorded_route',

              splits: {},
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

      before do
        stub_request(:get, server_url).to_return(body: config.to_json)
      end

      let(:cache_settings) { { expires_in: 1 } }
      subject do
        described_class.new(:app, server_url, caching_options: cache_settings)
      end

      describe '#load_config' do
        subject do
          described_class.new(:app, server_url, caching_options: cache_settings)
        end

        let(:expected_core) do
          Core.new do
            sitehub_cookie_name 'sitehub.recorded_route'
            proxy '/route_1' do
              route label: :label_1, url: 'http://lvl-up.uk/'
            end
          end.build
        end

        it 'loads config' do
          expect(subject.app).to be_nil
          subject.load_config

          expect(subject.app).to eq(expected_core)
        end

        it 'loads it from cache' do
          different_config = { proxies: [] }
          subject.load_config
          stub_request(:get, server_url).to_return(body: different_config.to_json)
          subject.load_config
          expect(subject.app).to eq(expected_core)
        end
      end

      describe '#call' do
        it 'calls the loaded_app' do
          response = [200, {}, []]

          app = proc do |env|
            expect(env).to eq(:env)
            response
          end
          expect(Core).to receive(:from_hash).and_return(double(build: app))

          expect(subject.call(:env)).to eq(response)
        end

        context 'config not retrievable' do
          let(:config_server) do
            instance_double(ConfigServer).tap do |config_server|
              expect(ConfigServer).to receive(:new).and_return(config_server)
            end
          end

          let(:env) { { ERRORS => [] } }

          context 'first call ever received' do
            it 'raises an error' do
              expected_message = 'error message'
              expect(config_server).to receive(:get).and_raise(ConfigServer::Error, expected_message)
              expect { subject.call(env) }.to raise_error(ConfigServer::Error, expected_message)
            end

            it 'does not write anything to errors' do
              expect(config_server).to receive(:get).and_raise(ConfigServer::Error)

              expect { subject.call(env) }.to raise_error(ConfigServer::Error)
              expect(env[ERRORS]).to be_empty
            end
          end

          context 'config previously loaded' do
            subject do
              described_class.new(:app, server_url, caching_options: cache_settings)
            end

            let(:response) { [200, {}, []] }
            before do
              app = proc do |_env|
                response
              end

              expect(config_server).to receive(:get).and_return(config)
              expect(Core).to receive(:from_hash).with(config).and_return(double(build: app))
              subject.call(env)
              Timecop.travel(2)
            end

            it 'retains the original config' do
              expect(config_server).to receive(:get).and_raise(ConfigServer::Error)
              expect(subject.call(env)).to eq(response)
            end

            it 'writes an error to the error log' do
              expected_error_message = 'error message'
              expect(config_server).to receive(:get).and_raise(ConfigServer::Error, expected_error_message)

              subject.call(env)
              expect(env[ERRORS]).to include(expected_error_message)
            end
          end
        end
      end
    end
  end
end
