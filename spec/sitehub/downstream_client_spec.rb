require 'sitehub/downstream_client'

class SiteHub
  describe DownstreamClient do
    include_context :rack_http_request
    include_context :http_proxy_rules

    let(:current_version_url) { 'http://127.0.0.1:10111' }
    let(:mapped_path) { '/path' }

    let(:app) do
      described_class.new
    end

    let(:body) { 'body' }
    let(:http_headers) { {} }
    let(:http_method) { :get }
    let(:env) { env_for(path: mapped_path, env: http_headers, method: http_method) }

    let(:request) do
      SiteHub::Request.new(env: env).tap do |request|
        request.map(mapped_path, current_version_url)
      end
    end

    describe '#call' do
      context 'downstream request' do
        before do
          stub_request(http_method, current_version_url).to_return(body: 'body')
        end

        context 'non get request' do
          let(:http_method) { :put }
          it 'preserves the body when forwarding request' do
            stub_request(http_method, current_version_url).with(body: body)
            subject.call(request)
          end
        end

        it 'preserves the headers when forwarding request' do
          http_headers['HTTP_HEADER'] = 'value'
          subject.call(request)
          assert_requested http_method, current_version_url, headers: { 'Header' => 'value' }
        end

        it_behaves_like 'prohibited_header_filter' do
          include_context :rack_headers

          subject do
            headers = to_rack_headers(prohibited_headers.merge(permitted_header => 'value'))
            headers.each do |key, value|
              http_headers[key] = value
            end

            subject = described_class.new
            subject.call(request)

            WebMock::RequestRegistry.instance.requested_signatures.hash.keys.first.headers
          end
        end

        context 'headers' do
          # used to identify the originally requested host
          context 'x-forwarded-host header' do
            context 'header not present' do
              it 'assigns it to the requested host' do
                subject.call(request)
                assert_requested :get, current_version_url, headers: { 'X-FORWARDED-HOST' => 'example.org' }
              end
            end

            context 'header already present' do
              it 'appends the host to the existing value' do
                http_headers['HTTP_X_FORWARDED_HOST'] = 'first.host,second.host'
                subject.call(request)
                assert_requested :get, current_version_url,
                                 headers: { 'X-FORWARDED-HOST' => 'first.host,second.host,example.org' }
              end
            end
          end

          # used for identifying the originating IP address of a request.
          context 'x-forwarded-for' do
            context 'header not present' do
              it 'introduces it assigned to the value the remote-addr http header' do
                env = env_for(path: mapped_path)

                subject = described_class.new
                subject.call(request)

                x_forwarded_for_header = Constants::HttpHeaderKeys::X_FORWARDED_FOR_HEADER
                expected_headers = { x_forwarded_for_header => env['REMOTE_ADDR'] }
                assert_requested :get, current_version_url, headers: expected_headers
              end
            end

            context 'already present' do
              it 'appends the value of the remote-addr header to it' do
                x_forwarded_for_header = Constants::RackHttpHeaderKeys::X_FORWARDED_FOR

                http_headers[x_forwarded_for_header] = 'first_host_ip'
                subject = described_class.new
                subject.call(request)

                expected_header_value = "first_host_ip,#{env['REMOTE_ADDR']}"
                expected_headers = { Constants::HttpHeaderKeys::X_FORWARDED_FOR_HEADER => expected_header_value }
                assert_requested :get, current_version_url, headers: expected_headers
              end
            end
          end
        end
      end
    end
  end
end
