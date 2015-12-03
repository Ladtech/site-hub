require 'sitehub/forward_proxy'

class SiteHub
  describe ForwardProxy do

    let(:current_version_url) { 'http://does.not.exist.com' }
    let(:mapped_path) { '/path' }

    subject do
      described_class.new(id: :id, url: current_version_url, mapped_path: mapped_path,sitehub_cookie_name: :cookie_name)
    end

    let(:app) do
      subject
    end

    it 'includes Resolver' do
      expect(subject).to be_a(Resolver)
    end

    it 'includes Rules' do
      expect(subject).to be_a(Rules)
    end

    describe '#call' do
      before do
        WebMock.enable!
        stub_request(:get, current_version_url).to_return(:body => 'body')
      end

      context 'recorded routes cookie' do
        it 'drops a cookie using the name of the sitehub_cookie_name containing the id' do
          get(mapped_path, {})
          expect(last_response.cookies[:cookie_name.to_s]).to eq(value: :id.to_s, path: subject.mapped_path)
        end

        context 'recorded_routes_cookie_path not set' do
          it 'sets the path to be the request path' do
            get(mapped_path, {})
            expect(last_response.cookies[:cookie_name.to_s][:path]).to eq(mapped_path)
          end
        end

        context 'recorded_routes_cookie_path set' do

          let(:expected_path){'/expected_path'}

          subject do
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



      it 'passes request mapping information in to the environment hash' do
        get(mapped_path, {})
        expect(last_request.env[REQUEST_MAPPING]).to eq(RequestMapping.new(source_url: "http://example.org#{mapped_path}", mapped_url: current_version_url, mapped_path: mapped_path))
      end

      context 'downstream call' do
        context 'it fails' do
          before do
            WebMock.disable!
          end
          it 'adds an error to be logged' do
            env = {ERRORS.to_s => []}
            get(mapped_path, {}, env)
            expect(last_request.env[ERRORS]).to eq(["unable to resolve server address"])
          end

          describe 'parameters to callback' do
            it 'calls the callback with an error response' do
              expect(described_class::ERROR_RESPONSE).to receive(:dup).and_return(described_class::ERROR_RESPONSE)
              env = {ERRORS.to_s => []}
              get(mapped_path, {}, env)

              expect(last_response.body).to eq(described_class::ERROR_RESPONSE.body.join)
              expect(last_response.headers).to eq(described_class::ERROR_RESPONSE.headers)
              expect(last_response.status).to eq(described_class::ERROR_RESPONSE.status)
            end

            it 'passes the request mapping' do
              env = { ERRORS.to_s => []}
              get(mapped_path, {}, env)
              expect(last_request.env[REQUEST_MAPPING]).to eq(RequestMapping.new(source_url: "http://example.org#{mapped_path}", mapped_url: current_version_url, mapped_path: mapped_path))
            end
          end
        end


        it 'translates the header names back in to the http compatible names' do
          get(mapped_path, {})
          expect(last_response.headers).to include('Content-Length')
          expect(last_response.headers).to_not include('CONTENT_LENGTH')
        end

        context 'adding http_x_forwarded_host header' do
          context 'when not present in the original request' do
            it 'appends original request url with port' do
              get(mapped_path, {})
              assert_requested :get, current_version_url, headers: {'X-FORWARDED-HOST' => 'example.org:80'}
            end
          end

          context 'when present in the original request' do
            it 'appends original request url without port' do
              get(mapped_path, {}, 'HTTP_X_FORWARDED_HOST' => 'staging.com')
              assert_requested :get, current_version_url, headers: {'X-FORWARDED-HOST' => 'staging.com,staging.com'}
            end
          end

          it 'preserves the body when forwarding request' do
            body = {"key" => "value"}
            stub_request(:put, current_version_url).with(:body => body)

            put(mapped_path, body)
          end

          it 'preserves the headers when forwarding request' do
            get(mapped_path, '', 'HTTP_HEADER' => 'value')
            assert_requested :get, current_version_url, headers: {'Header' => 'value'}
          end
        end

      end
    end
  end
end