class SiteHub
  module Middleware
    describe ErrorHandling do
      describe '#call' do
        subject(:app) do
          app = proc { raise }
          described_class.new(app)
        end
        context 'it fails' do
          before do
            WebMock.disable!
          end
          it 'adds an error to be logged' do
            env = { ERRORS.to_s => [] }
            get('/', {}, env)
            expect(last_request.env[ERRORS]).to_not be_empty
          end

          describe 'parameters to callback' do
            it 'calls the callback with an error response' do
              expect(described_class::ERROR_RESPONSE).to receive(:dup).and_return(described_class::ERROR_RESPONSE)
              env = { ERRORS.to_s => [] }
              get('/', {}, env)

              expect(last_response.body).to eq(described_class::ERROR_RESPONSE.body.join)
              expect(last_response.headers).to eq(described_class::ERROR_RESPONSE.headers)
              expect(last_response.status).to eq(described_class::ERROR_RESPONSE.status)
            end
          end
        end
      end
    end
  end
end
