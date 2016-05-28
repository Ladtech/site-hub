require 'sitehub/forward_proxies'

class SiteHub
  describe ForwardProxies do
    let(:base_url) { 'http://google.com' }
    let(:application_root) { '/application_url' }
    let(:forward_proxy_builder) do
      ForwardProxyBuilder.new(mapped_path: application_root).tap do |builder|
        builder.split url: base_url, label: :current, percentage: 100
      end
    end

    subject do
      described_class.new.tap do |route_set|
        route_set << forward_proxy_builder
      end
    end

    before do
      subject.init
    end

    describe '#init' do
      it 'builds all of the forward_proxies' do
        expect(subject.forward_proxies[application_root]).to receive(:build).and_call_original
        subject.init
      end
    end

    describe '#mapped_route' do
      let(:request) { Rack::Request.new({}) }
      let(:more_specific_proxy_builder) do
        ForwardProxyBuilder.new(url: "#{base_url}/sub_url", mapped_path: "#{application_root}/sub_url")
      end

      context 'regex match on path' do
        let(:fuzzy_matcher) do
          ForwardProxyBuilder.new(url: "#{base_url}/$1/view", mapped_path: %r{#{application_root}/(.*)/view})
        end
        subject do
          described_class.new.tap do |route_set|
            route_set << fuzzy_matcher
          end
        end

        it 'matches and subsitutes the captured group' do
          mapped_endpoint = subject.mapped_route(path: "#{application_root}/123/view", request: request)
          expected_endpoint = fuzzy_matcher.resolve(env: {})
          expect(mapped_endpoint).to eq(expected_endpoint)
        end
      end

      context 'exact match on path' do
        it 'proxies to the requested path' do
          mapped_endpoint = subject.mapped_route(path: application_root, request: request)
          expected_endpoint = forward_proxy_builder.resolve(env: {})
          expect(mapped_endpoint).to eq(expected_endpoint)
        end
      end

      context 'when more specific route is configured first' do
        subject do
          described_class.new.tap do |route_set|
            route_set << more_specific_proxy_builder
            route_set << forward_proxy_builder
          end
        end

        it 'matches the first endpoint' do
          expected_endpoint = more_specific_proxy_builder.resolve(env: {})
          mapped_endpoint = subject.mapped_route(path: "#{application_root}/sub_url", request: request)
          expect(mapped_endpoint).to eq(expected_endpoint)
        end
      end
    end

    describe '#call' do
      context 'mapped_route not found' do
        let(:app) do
          subject
        end

        it 'returns a 404' do
          expect(get('/missing').status).to eq(404)
        end
      end

      context 'mapped_route found' do
        let(:app) do
          subject
        end

        it 'uses the forward proxy' do
          subject
          expect(forward_proxy_builder.endpoints[:current]).to receive(:call) do
            [200, {}, []]
          end
          expect(get(application_root).status).to eq(200)
        end
      end
    end
  end
end
