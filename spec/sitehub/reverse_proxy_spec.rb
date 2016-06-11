class SiteHub
  describe ReverseProxy do
    include_context :middleware_test

    let(:mapped_path) { '/orders' }
    let(:user_facing_app_url) { "http://example.org#{mapped_path}" }

    let(:downstream_mapping) { 'https://downstream.com/app1/orders' }
    let(:downstream_location) { "#{downstream_mapping}/123/confirmation" }

    let(:request_mapping) do
      RequestMapping.new source_url: "#{user_facing_app_url}/123/payment",
                         mapped_url: downstream_mapping,
                         mapped_path: mapped_path
    end

    let(:app) do
      proc { downstream_response }
    end
    let(:downstream_response) { Rack::Response.new('downstream', 200, 'header1' => 'header1') }

    subject(:reverse_proxy) { described_class.new(app, []) }
    let(:env) { { REQUEST_MAPPING => request_mapping } }

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
              .with(downstream_response.headers, substitute_domain: URI(request_mapping.source_url).host)

            reverse_proxy.call(env)
          end
        end

        context 'downstream response does not contain a cookie' do
          it 'does not attempt to rewrite the cookies' do
            downstream_headers = downstream_response.headers
            downstream_headers[HttpHeaders::LOCATION_HEADER] = downstream_location
            expect(reverse_proxy).not_to receive(:rewrite_cookies)
            reverse_proxy.call(env)
          end
        end
      end

      context 'location header' do
        context 'reverse proxy defined' do
          # Location, Content-Location and URI
          it 'rewrites the header' do
            downstream_response.headers[HttpHeaders::LOCATION_HEADER] = downstream_location

            expect(reverse_proxy)
              .to receive(:interpolate_location)
              .with(downstream_location, request_mapping.source_url)
              .and_return(:interpolated_location)

            reverse_proxy.call(env)
            expect(downstream_response.headers[HttpHeaders::LOCATION_HEADER]).to eq(:interpolated_location)
          end
        end

        # context 'reverse proxy not defined' do
        #   it 'leaves the header alone' do
        #     downstream_response.headers[HttpHeaders::LOCATION_HEADER] = downstream_location
        #
        #     expect(reverse_proxy)
        #         .to receive(:interpolate_location)
        #                 .with(downstream_location, request_mapping.source_url)
        #                 .and_return(:nil)
        #
        #     reverse_proxy.call(env)
        #     expect(downstream_response.headers[HttpHeaders::LOCATION_HEADER]).to eq(downstream_location)
        #   end
        # end
      end
    end

    describe '#interpolate_location' do
      it 'changes the domain' do
        expect(reverse_proxy.interpolate_location(downstream_location, request_mapping.source_url)).to eq('http://example.org/app1/orders/123/confirmation')
      end

      context 'there is a directive that applies' do
        context 'matcher is a regexp' do
          subject do
            directive = { %r{#{downstream_mapping}/(.*)/confirmation} => '/confirmation/$1' }
            described_class.new(inner_app, directive)
          end
          it 'changes the path' do
            expect(subject.interpolate_location(downstream_location, request_mapping.source_url)).to eq('http://example.org/confirmation/123')
          end
        end

        context 'matcher is a string' do
          let(:downstream_url) { 'http://downstream.com/confirmation' }
          subject do
            directive = { downstream_url => '/congratulations' }
            described_class.new(inner_app, directive)
          end
          it 'changes the path' do
            actual = subject.interpolate_location(downstream_url, request_mapping.source_url)
            expected = 'http://example.org/congratulations'
            expect(actual).to eq(expected)
          end
        end
      end
    end
  end
end
