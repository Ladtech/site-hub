require 'sitehub/constants'
require 'sitehub/logging/access_logger'
require 'stringio'

class SiteHub
  module Logging
    describe AccessLogger do
      RackHttpHeaderKeys = Constants::RackHttpHeaderKeys
      HttpHeaderKeys = Constants::HttpHeaderKeys

      let(:logger) { StringIO.new }

      let(:app) do
        proc { [200, {}, []] }
      end

      subject do
        described_class.new(app, logger)
      end

      describe '#initialize' do
        context 'logger supplied' do
          it 'sets logger to that logger' do
            expect(described_class.new(:app, :custom_logger).logger).to eq(LogWrapper.new(:custom_logger))
          end
        end

        context 'logger not supplied' do
          it 'sets the logger to go to STDERR' do
            expect(::Logger).to receive(:new).with(STDOUT).and_return(:logging)
            expect(described_class.new(:app).logger).to eq(LogWrapper.new(:logging))
          end
        end
      end

      describe '#call' do
        let(:env) do
          { RackHttpHeaderKeys::QUERY_STRING => '',
            RackHttpHeaderKeys::PATH_INFO => 'path_info',
            RackHttpHeaderKeys::TRANSACTION_ID => :transaction_id,
            RackHttpHeaderKeys::HTTP_VERSION => '1.1' }
        end

        let(:request) do
          Request.new(env: env, mapped_url: :mapped_url.to_s, mapped_path: :mapped_path.to_s)
        end

        before do
          env[REQUEST] = request
          subject.call(env)
        end

        let(:args) { { request: request, downstream_response: Rack::Response.new } }
        it 'logs the request / response details in the required format' do
          expect(subject).to receive(:log_template).and_return(:template.to_s)
          expect(logger).to receive(:write).with(:template.to_s)

          subject.call(env)
        end

        context 'query string' do
          let(:query_string) { RackHttpHeaderKeys::QUERY_STRING }
          context 'present' do
            it 'logs it' do
              env[query_string] = 'query'
              subject.call(env)
              expect(logger.string).to include('?query')
            end
          end

          context 'not present' do
            it 'is not logged' do
              subject.call(env)
              expect(logger.string).to_not include('?')
            end
          end
        end

        it 'logs the transaction id' do
          subject.call(env)

          expect(logger.string).to include('transaction_id:transaction_id')
        end

        it 'logs the response status' do
          subject.call(env)

          expect(logger.string).to include(args[:downstream_response].status.to_s)
        end

        it 'logs the downstream url that was proxied to' do
          subject.call(env)

          expect(logger.string).to include("#{env[RackHttpHeaderKeys::PATH_INFO]} => mapped_url")
        end

        context '404 returned, i.e. no downstream call made' do
          let(:request) { Request.new(env: env, mapped_url: nil, mapped_path: nil) }
          it 'does not log the down stream url' do
            subject.call(env)
            expect(logger.string).to include("=> #{EMPTY_STRING} #{env[RackHttpHeaderKeys::HTTP_VERSION]}")
          end
        end
      end

      describe '#extract_content_length' do
        context 'content length header not present' do
          it 'returns -' do
            expect(subject.extract_content_length({})).to eq('-')
          end
        end

        context 'content length header not present' do
          let(:content_length) { HttpHeaderKeys::CONTENT_LENGTH }
          context 'it is 0' do
            it 'returns -' do
              expect(subject.extract_content_length(content_length => 0)).to eq('-')
            end
          end
          context 'it is set to a number other than 0'
          it 'returns the number' do
            expect(subject.extract_content_length(content_length => 5)).to eq(5)
          end
        end
      end
    end
  end
end
