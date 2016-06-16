require 'sitehub/middleware/logging/request_log'

class SiteHub
  module Middleware
    module Logging
      describe RequestLog do
        include_context :rack_http_request

        RackHttpHeaderKeys = Constants::RackHttpHeaderKeys

        let(:response_headers) do
          env = { RackHttpHeaderKeys::QUERY_STRING => '',
                  RackHttpHeaderKeys::TRANSACTION_ID => :transaction_id,
                  RackHttpHeaderKeys::HTTP_VERSION => '1.1' }
          HttpHeadersObject.from_rack_env(env)
        end

        let(:request_headers) do
          {}
        end

        let(:query_string) { '' }

        let(:request) do
          env = env_for(path: "/#{query_string}", env: request_headers)
          Request.new(env: env).tap do |request|
            request.map :mapped_path.to_s, :mapped_url.to_s
          end
        end

        let(:response) do
          headers = env_for(path: '/', env: response_headers)
          Response.new([], 200, headers)
        end

        subject do
          described_class.new(request, response)
        end

        describe '#to_s' do
          context 'query string' do
            let(:query_string) { RackHttpHeaderKeys::QUERY_STRING }
            context 'present' do
              let(:query_string) { '?query' }
              it 'logs it' do
                expect(subject.to_s).to include(query_string)
              end
            end

            context 'not present' do
              let(:query_string) { '' }
              it 'is not logged' do
                expect(subject.to_s).to include(query_string)
              end
            end
          end

          it 'logs the transaction id' do
            request_headers[RackHttpHeaderKeys::TRANSACTION_ID] = :transaction_id
            expect(subject.to_s).to include('transaction_id:transaction_id')
          end

          it 'logs the response status' do
            expect(subject.to_s).to include(response.status.to_s)
          end

          it 'logs the downstream url that was proxied to' do
            expect(subject.to_s).to include("#{request.path} => mapped_url")
          end

          context '404 returned, i.e. no downstream call made' do
            let(:request) do
              env = env_for(path: "/#{query_string}", env: request_headers)
              Request.new(env: env)
            end
            it 'does not log the down stream url' do
              expect(subject.to_s).to include("=> #{EMPTY_STRING} #{request.http_version}")
            end
          end
        end

        describe '#extract_content_length' do
          context 'content length header not present' do
            it 'returns -' do
              expect(subject.extract_content_length).to eq('-')
            end
          end

          context 'content length header not present' do
            context 'it is 0' do
              it 'returns -' do
                response_headers[Constants::HttpHeaderKeys::CONTENT_LENGTH] = 0
                expect(subject.extract_content_length).to eq('-')
              end
            end

            context 'it is set to a number other than 0' do
              it 'returns the number' do
                response_headers[Constants::HttpHeaderKeys::CONTENT_LENGTH] = 5
                expect(subject.extract_content_length).to eq(5)
              end
            end
          end
        end
      end
    end
  end
end
