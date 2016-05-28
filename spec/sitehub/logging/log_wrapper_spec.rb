require 'sitehub/logging/log_wrapper'
class SiteHub
  module Logging
    describe LogWrapper do
      describe '#write' do
        let(:logger) { double('logger') }
        subject do
          described_class.new(logger)
        end

        context 'logger responds to <<' do
          it 'calls << when writing out the log' do
            message = 'message'
            expect(logger).to receive(:<<).with(message)
            subject.write(message)
          end
        end

        context 'logger responds to write' do
          it 'calls << when writing out the log' do
            message = 'message'
            expect(logger).to receive(:write).with(message)
            subject.write(message)
          end
        end
      end
    end
  end
end
