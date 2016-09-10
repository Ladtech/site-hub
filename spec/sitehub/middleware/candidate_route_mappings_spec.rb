require 'sitehub/middleware/candidate_route_mappings'

class SiteHub
  module Middleware
    describe CandidateRouteMappings do
      let(:base_url) { 'http://google.com' }
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

      shared_examples 'getter setter' do |default: nil|
        let(:method_name) { self.class.parent_groups[1].description.delete('#') }
        if default
          it 'defaults' do
            expect(subject.public_send(method_name)).to eq(default)
          end
        end

        it 'can be set' do
          custom_value = 'value'
          subject.public_send(method_name, custom_value)
          expect(subject.public_send(method_name)).to eq(custom_value)
        end
      end

      describe '#sitehub_cookie_path' do
        it_behaves_like 'getter setter', default: RECORDED_ROUTES_COOKIE_PATH
      end

      describe '#sitehub_cookie_name' do
        it_behaves_like 'getter setter', default: RECORDED_ROUTES_COOKIE
      end

      describe '#add_route' do
        def route(app, id:)
          Route.new(app,
                    id: id,
                    sitehub_cookie_name: RECORDED_ROUTES_COOKIE,
                    sitehub_cookie_path: nil)
        end

        context 'candidate_routes as parameter' do
          it 'sets it' do
            another_mapping = '/mapping'
            candidate_routes = CandidateRoutes.new(version_cookie: TrackingCookieDefinition.new(:sitehub_cookie_name), mapped_path: another_mapping)
            subject.add_route candidate_routes: candidate_routes
            expect(subject[another_mapping]).to be(candidate_routes)
          end
        end

        context 'mapped_path' do
          let(:expected_route) do
            proxy = ForwardProxy.new(mapped_path: expected_mapping, mapped_url: base_url)
            route(proxy, id: :current)
          end

          context 'mapped_path is a string' do
            let(:mapped_path) { 'string' }
            let(:expected_mapping) { mapped_path }
            it 'stores the route against that strubg' do
              expect(subject[mapped_path][:current]).to eq(expected_route)
            end
          end

          context 'mapped_path is a valid regex' do
            let(:mapped_path) { /regular_expression/ }
            let(:expected_mapping) { mapped_path }
            it 'stores the route against that regexp' do
              expect(subject[mapped_path][:current]).to eq(expected_route)
            end
          end

          context 'is a string containing a valid regexp' do
            let(:expected_mapping) { /regexp/ }
            let(:mapped_path) { '%r{regexp}' }
            it 'stores the route against the string coverted to a regexp' do
              expect(subject[expected_mapping][:current]).to eq(expected_route)
            end
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
            expect(forward_proxy_builder.candidates[Identifier.new(:current)]).to receive(:call) do
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
