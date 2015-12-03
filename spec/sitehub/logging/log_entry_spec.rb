require 'sitehub/logging/log_entry'
class SiteHub
  module Logging
    describe LogEntry do
      describe '#initialize' do

        let(:time){Time.now}
        subject do
          described_class.new(:message, time)
        end

        it 'sets the message' do
          expect(subject.message).to be(:message)
        end

        it 'sets the time' do
          expect(subject.time).to be(time)
        end

        context 'time not supplied' do
          subject do
            described_class.new(:message)
          end
          it 'defaults the time' do
            expect(Time).to receive(:now).and_return(:current_time)
            expect(subject.time).to be(:current_time)
          end
        end


      end
    end
  end
end