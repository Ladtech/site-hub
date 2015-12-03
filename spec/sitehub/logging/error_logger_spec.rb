require 'sitehub/logging/error_logger'

class SiteHub
  module Logging
    describe ErrorLogger do

      let(:app){ proc{[200, {}, []]}}
      subject { described_class.new(app) }

      describe '#initialize' do
        context 'logger supplied' do
          it 'sets logger to that logger' do
            expect(described_class.new(:app, :custom_logger).logger).to eq(LogWrapper.new(:custom_logger))
          end
        end

        context 'logger not supplied' do
          it 'sets the logger to go to STDERR' do
            expect(::Logger).to receive(:new).with(STDERR).and_return(:logging)
            expect(described_class.new(:app).logger).to eq(LogWrapper.new(:logging))
          end
        end
      end

      describe '#before_call' do
        it 'adds a collection hold errors' do
          env = {}
          subject.call(env)
          expect(env[ERRORS]).to eq([])
        end
      end

      describe '#call' do
        let(:output) { StringIO.new }
        let(:logger) { Logger.new(output) }
        let(:error_message) { 'error' }
        let(:errors) do
          Logging::LogStash.new.tap do |stash|
            stash << error_message
          end
        end
        subject { described_class.new(app, logger) }

        context 'errors have occurred' do
          it 'logs errors' do
            log_message = subject.log_message(error: error_message, transaction_id: :transaction_id)
            subject.call({ERRORS => errors, Constants::RackHttpHeaderKeys::TRANSACTION_ID => :transaction_id})
            expect(output.string).to eq(log_message)
          end
        end

        context 'no errors have occured' do
          it 'does not log anything' do
            expect(logger).to_not receive(:write)
            subject.call({ERRORS => []})
          end
        end
      end

      describe '#log_message' do
        let(:error) { 'error' }
        it 'contains the time and date' do
          now = Time.now
          expect(Time).to receive(:now).and_return(now)
          expected_time = now.strftime("%d/%b/%Y:%H:%M:%S %z")
          expect(subject.log_message(error: error, transaction_id: :transaction_id)).to start_with("[#{expected_time}]")
        end

        it 'logs statements made against blah' do

          expect(subject.log_message(error: error, transaction_id: :transaction_id)).to match(/ERROR: .* -  ?#{error}$/)
        end

        it 'contains the transation id of the request' do
          expect(subject.log_message(error: error, transaction_id: :transaction_id)).to include("ERROR: #{:transaction_id}")
        end
      end
    end
  end
end
