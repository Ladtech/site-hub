require 'sitehub/middleware/mappings'

class SiteHub
  module Middleware
    describe Mappings do
      let(:base_url) { 'http://google.com' }
      let(:mapped_path) { '/app' }
      let(:mapped_path) { '/application_url' }

      let(:forward_proxy_builder) do
        subject.values.first
      end

      subject do
        base_url = base_url()
        described_class.new.tap do |route_set|
          route_set.add_route(mapped_path: mapped_path) do |builder|
            builder.split url: base_url, label: :current, percentage: 100
          end
        end.init
      end

      before do
        subject.init
      end

      describe '#add_proxy' do
        def route(app, id:)
          Route.new(app,
                    id: id,
                    sitehub_cookie_name: RECORDED_ROUTES_COOKIE,
                    sitehub_cookie_path: nil)
        end

        context 'RouteBuilder as parameter' do
          it 'sets it' do
            another_mapping = '/mapping'
            route = RouteCandidates.new(sitehub_cookie_name: :sitehub_cookie_name, mapped_path: another_mapping)
            subject.add_route route_builder: route
            expect(subject[another_mapping]).to be(route)
          end
        end

        context 'url specified' do
          let(:expected_route) do
            proxy = ForwardProxy.new(mapped_path: mapped_path, mapped_url: :url)
            route(proxy, id: :default)
          end

          it 'adds a default proxy for the given mapping' do
            subject.add_route(url: :url, mapped_path: mapped_path)
            route = subject[mapped_path]
            expect(route.default_route).to eq(expected_route)
          end
        end
      end

      describe '#call' do
        let(:app) do
          subject
        end

        context 'mapped_route not found' do
          it 'returns a 404' do
            expect(get('/missing').status).to eq(404)
          end
        end

        context 'mapped_route found' do
          it 'uses the forward proxy' do
            subject
            expect(forward_proxy_builder.routes[Identifier.new(:current)]).to receive(:call) do
              [200, {}, []]
            end
            expect(get(mapped_path).status).to eq(200)
          end
        end
      end

      describe '#init' do
        it 'builds all of the forward_proxies' do
          expect(subject[mapped_path]).to receive(:build).and_call_original
          subject.init
        end
      end

      describe '#mapped_route' do
        let(:request) { Rack::Request.new({}) }

        before do
          subject.sitehub_cookie_name :cookie_name
          subject.add_route mapped_path: mapped_path do
            route label: :preset_id, url: :url
          end
        end

        it 'uses the id in the sitehub_cookie to resolve the correct route' do
          request.cookies[:cookie_name] = :preset_id
          expect(forward_proxy_builder).to receive(:resolve).with(id: :preset_id, env: request.env).and_call_original
          subject.mapped_route(path: mapped_path, request: request)
        end

        context 'regex match on path' do
          let(:fuzzy_matcher) do
            subject.values.first
          end

          subject do
            described_class.new.tap do |route_set|
              route_set.add_route url: "#{base_url}/$1/view", mapped_path: %r{#{mapped_path}/(.*)/view}
            end
          end

          it 'matches and subsitutes the captured group' do
            mapped_endpoint = subject.mapped_route(path: "#{mapped_path}/123/view", request: request)
            expected_endpoint = fuzzy_matcher.resolve(env: {})
            expect(mapped_endpoint).to eq(expected_endpoint)
          end
        end

        context 'exact match on path' do
          it 'proxies to the requested path' do
            mapped_endpoint = subject.mapped_route(path: mapped_path, request: request)
            expected_endpoint = forward_proxy_builder.resolve(env: {})
            expect(mapped_endpoint).to eq(expected_endpoint)
          end
        end

        context 'when more specific route is configured first' do
          let(:more_specific_proxy_builder) do
            subject.values.first
          end

          subject do
            described_class.new.tap do |route_set|
              route_set.add_route(url: "#{base_url}/sub_url", mapped_path: "#{mapped_path}/sub_url")
              route_set.add_route(mapped_path: mapped_path, url: base_url)
            end
          end

          it 'matches the first endpoint' do
            expected_endpoint = more_specific_proxy_builder.resolve(env: {})
            mapped_endpoint = subject.mapped_route(path: "#{mapped_path}/sub_url", request: request)
            expect(mapped_endpoint).to eq(expected_endpoint)
          end
        end
      end
    end
  end
end
