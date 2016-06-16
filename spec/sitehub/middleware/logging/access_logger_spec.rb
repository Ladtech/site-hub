require 'sitehub/constants'
require 'sitehub/middleware/logging/access_logger'
require 'stringio'

class SiteHub
  module Middleware
    module Logging
      describe AccessLogger do
        RackHttpHeaderKeys = Constants::RackHttpHeaderKeys
        HttpHeaderKeys = Constants::HttpHeaderKeys
        include_context :rack_http_request

        let(:logger) { StringIO.new }

        let(:env) { env_for(path: '/') }

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
          let(:expected_response) { Response.new([], 200, {}) }

          let(:app) do
            proc { expected_response }
          end

          it 'logs the request / response details' do
            expected_request = Request.new(env: env)

            subject.call(env)
            expect(logger.string).to eq(RequestLog.new(expected_request, expected_response).to_s)
          end
        end
      end
    end
  end
end
