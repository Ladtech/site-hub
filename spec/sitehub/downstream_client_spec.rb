require 'sitehub/downstream_client'

class SiteHub
  describe DownstreamClient do
    include_context :rack_request
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
          let(:env) do
            env_for(path: mapped_path,
                    env: http_headers,
                    params_or_body: body,
                    method: http_method)
          end

          it 'preserves the body when forwarding request' do
            stub_request(http_method, current_version_url)
            subject.call(request)
            assert_requested http_method, current_version_url, body: body
          end
        end

        it 'preserves the headers when forwarding request' do
          http_headers['HTTP_HEADER'] = 'value'
          subject.call(request)
          assert_requested http_method, current_version_url, headers: { 'Header' => 'value' }
        end

        it_behaves_like 'prohibited_header_filter' do
          include_context :rack_request

          subject do
            headers = format_http_to_rack_headers(prohibited_headers.merge(permitted_header => 'value'))
            headers.each do |key, value|
              http_headers[key] = value
            end

            subject = described_class.new
            subject.call(request)

            WebMock::RequestRegistry.instance.requested_signatures.hash.keys.first.headers
          end
        end
      end
    end
  end
end
