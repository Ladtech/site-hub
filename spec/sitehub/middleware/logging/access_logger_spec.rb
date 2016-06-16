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

        let(:response) { Response.new([], 200, {}) }

        let(:request) do
          Request.new(env: env_for(path: '/'), mapped_url: :mapped_url.to_s, mapped_path: :mapped_path.to_s)
        end

        let(:app) do
          proc { response }
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
          it 'logs the request / response details' do
            subject.call(REQUEST => request)
            expect(logger.string).to eq(RequestLog.new(request, response).to_s)
          end
        end
      end
    end
  end
end
