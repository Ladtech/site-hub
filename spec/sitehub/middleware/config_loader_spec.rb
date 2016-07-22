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
                candidates: [
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

      subject do
        described_class.new(:app, server_url)
      end

      describe '#load_config' do
        it 'loads config' do
          expect(subject.app).to be_nil
          subject.load_config

          expected_core = Core.new do
            sitehub_cookie_name 'sitehub.recorded_route'
            proxy '/route_1' do
              route label: :label_1, url: 'http://lvl-up.uk/'
            end
          end.build

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
      end
    end
  end
end
