require 'sitehub/middleware/logging/log_stash'

class SiteHub
  module Middleware
    module Logging
      describe LogStash do
        it 'inherits Array' do
          expect(subject).to be_a_kind_of(Array)
        end

        describe '#<<' do
          it 'adds a LogEntry' do
            allow(Time).to receive(:now).and_return(:current_time)
            subject << :message
            expect(subject).to eq([LogEntry.new(:message)])
          end
        end
      end
    end
  end
end
