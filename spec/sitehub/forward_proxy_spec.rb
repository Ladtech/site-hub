# rubocop:disable Metrics/ClassLength
require 'sitehub/forward_proxy'

class SiteHub
  describe ForwardProxy do
    include_context :http_proxy_rules

    let(:current_version_url) { 'http://127.0.0.1:10111' }
    let(:mapped_path) { '/path' }

    let(:app) do
      described_class.new(id: :id,
                          url: current_version_url,
                          mapped_path: mapped_path,
                          sitehub_cookie_name: :cookie_name)
    end

    it 'includes Resolver' do
      expect(app).to be_a(Resolver)
    end

    it 'includes Rules' do
      expect(app).to be_a(Rules)
    end

    describe '#call' do
      context 'downstream request' do
        before do
          stub_request(:get, current_version_url).to_return(body: 'body')
        end

        it 'preserves the body when forwarding request' do
          body = { 'key' => 'value' }
          stub_request(:put, current_version_url).with(body: body)
          put(mapped_path, body)
        end

        it 'preserves the headers when forwarding request' do
          get(mapped_path, '', 'HTTP_HEADER' => 'value')
          assert_requested :get, current_version_url, headers: { 'Header' => 'value' }
        end

        context 'it fails' do
          before do
            WebMock.disable!
          end
          it 'adds an error to be logged' do
            env = { ERRORS.to_s => [] }
            get(mapped_path, {}, env)
            expect(last_request.env[ERRORS]).to_not be_empty
          end

          describe 'parameters to callback' do
            it 'calls the callback with an error response' do
              expect(described_class::ERROR_RESPONSE).to receive(:dup).and_return(described_class::ERROR_RESPONSE)
              env = { ERRORS.to_s => [] }
              get(mapped_path, {}, env)

              expect(last_response.body).to eq(described_class::ERROR_RESPONSE.body.join)
              expect(last_response.headers).to eq(described_class::ERROR_RESPONSE.headers)
              expect(last_response.status).to eq(described_class::ERROR_RESPONSE.status)
            end
          end
        end

        it_behaves_like 'prohibited_header_filter' do
          include_context :rack_headers

          subject do
            http_headers = prohibited_headers.merge(permitted_header => 'value')
            get(mapped_path, {}, to_rack_headers(http_headers))
            WebMock::RequestRegistry.instance.requested_signatures.hash.keys.first.headers
          end
        end

        context 'headers' do
          # used to identify the originally requested host
          context 'x-forwarded-host header' do
            context 'header not present' do
              it 'assigns it to the requested host' do
                get(mapped_path, {})
                assert_requested :get, current_version_url, headers: { 'X-FORWARDED-HOST' => 'example.org' }
              end
            end

            context 'header already present' do
              it 'appends the host to the existing value' do
                get(mapped_path, {}, 'HTTP_X_FORWARDED_HOST' => 'first.host,second.host')
                assert_requested :get, current_version_url,
                                 headers: { 'X-FORWARDED-HOST' => 'first.host,second.host,example.org' }
              end
            end
          end

          # used for identifying the originating IP address of a request.
          context 'x-forwarded-for' do
            context 'header not present' do
              it 'introduces it assigned to the value the remote-addr http header' do
                x_forwarded_for_header = Constants::HttpHeaderKeys::X_FORWARDED_FOR_HEADER
                get(mapped_path)
                expected_headers = { x_forwarded_for_header => last_request.env['REMOTE_ADDR'] }
                assert_requested :get, current_version_url, headers: expected_headers
              end
            end

            context 'already present' do
              it 'appends the value of the remote-addr header to it' do
                x_forwarded_for_header = Constants::RackHttpHeaderKeys::X_FORWARDED_FOR
                get(mapped_path, {}, x_forwarded_for_header => 'first_host_ip')
                expected_header_value = "first_host_ip,#{last_request.env['REMOTE_ADDR']}"
                expected_headers = { Constants::HttpHeaderKeys::X_FORWARDED_FOR_HEADER => expected_header_value }
                assert_requested :get, current_version_url, headers: expected_headers
              end
            end
          end
        end
      end

      context 'response' do
        include_context :http_proxy_rules

        it 'passes request mapping information in to the environment hash' do
          expected_mapping = RequestMapping.new(source_url: "http://example.org#{mapped_path}",
                                                mapped_url: current_version_url,
                                                mapped_path: mapped_path)

          stub_request(:get, current_version_url)
          get(mapped_path, {})
          expect(last_request.env[REQUEST_MAPPING]).to eq(expected_mapping)
        end

        context 'recorded routes cookie' do
          before do
            stub_request(:get, current_version_url)
          end
          it 'drops a cookie using the name of the sitehub_cookie_name containing the id' do
            get(mapped_path, {})
            expect(last_response.cookies[:cookie_name.to_s]).to eq(value: :id.to_s, path: app.mapped_path)
          end

          context 'recorded_routes_cookie_path not set' do
            it 'sets the path to be the request path' do
              get(mapped_path, {})
              expect(last_response.cookies[:cookie_name.to_s][:path]).to eq(mapped_path)
            end
          end

          context 'recorded_routes_cookie_path set' do
            let(:expected_path) { '/expected_path' }

            subject(:app) do
              described_class.new(id: :id,
                                  url: current_version_url,
                                  mapped_path: mapped_path,
                                  sitehub_cookie_path: expected_path,
                                  sitehub_cookie_name: :cookie_name)
            end

            it 'is set as the path' do
              get(mapped_path, {})
              expect(last_response.cookies[:cookie_name.to_s][:path]).to eq(expected_path)
            end
          end
        end
      end
    end
  end
end
