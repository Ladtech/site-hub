class SiteHub
  module Middleware
    describe ReverseProxy do
      include_context :rack_request
      include_context :middleware_test
      HttpHeaderKeys = Constants::HttpHeaderKeys

      let(:mapped_path) { '/orders' }
      let(:user_facing_app_url) { "http://example.org#{mapped_path}" }

      let(:downstream_mapping) { 'https://downstream.com/app1/orders' }
      let(:downstream_location) { "#{downstream_mapping}/123/confirmation" }

      let(:env) { env_for(path: mapped_path) }

      let(:request) do
        Request.new(env: env).tap do |request|
          request.map mapped_path, downstream_mapping
        end
      end
      let(:request_mapping) { request.mapping }

      let(:app) do
        proc { downstream_response }
      end

      let(:downstream_response) { Rack::Response.new('downstream', 200, 'header1' => 'header1') }

      subject(:reverse_proxy) { described_class.new(app, []) }

      before do
        env[REQUEST] = request
      end

      describe '#call' do
        subject(:response) do
          status, headers, body = reverse_proxy.call(env).to_a
          Rack::Response.new(body, status, headers)
        end

        it 'copies the downstream body in to the response' do
          expect(response.body).to eq(downstream_response.body)
        end

        it 'copies the downstream headers in to the response' do
          expect(response.headers).to eq(downstream_response.headers)
        end

        it 'copies the downstream status in to the response' do
          expect(response.status).to eq(downstream_response.status)
        end

        context 'cookies' do
          context 'downstream response contains a cookie' do
            it 'rewrites it to use the upstream domain' do
              downstream_response.set_cookie('downstream.cookie', domain: '.downstream.com', value: 'value')

              expect(reverse_proxy)
                .to receive(:rewrite_cookies)
                .with(downstream_response.headers, substitute_domain: URI(request.mapping.source_url).host)

              reverse_proxy.call(env)
            end
          end

          context 'downstream response does not contain a cookie' do
            it 'does not attempt to rewrite the cookies' do
              downstream_headers = downstream_response.headers
              downstream_headers[HttpHeaderKeys::LOCATION_HEADER] = downstream_location
              expect(reverse_proxy).not_to receive(:rewrite_cookies)
              reverse_proxy.call(env)
            end
          end
        end

        context 'location header' do
          context 'reverse proxy defined' do
            subject(:reverse_proxy) do
              directive = { downstream_mapping => '/rewritten' }
              described_class.new(app, directive)
            end
            # Location, Content-Location and URI
            it 'rewrites the header' do
              downstream_response.headers[HttpHeaderKeys::LOCATION_HEADER] = downstream_mapping
              reverse_proxy.call(env)
              # TODO: come up with better way for getting source request address and reuse the test suite
              expect(downstream_response.headers[HttpHeaderKeys::LOCATION_HEADER]).to eq('http://example.org/rewritten')
            end
          end
        end

        context 'response' do
          include_context :http_proxy_rules

          let(:downstream_response) do
            Rack::Response.new('', 200, prohibited_headers.merge(permitted_header => 'value'))
          end

          subject(:app) do
            app = proc { downstream_response }
            described_class.new(app, [])
          end

          it_behaves_like 'prohibited_header_filter' do
            let(:subject) do
              get('/', {}, REQUEST => request).headers
            end
          end
        end
      end
    end
  end
end
