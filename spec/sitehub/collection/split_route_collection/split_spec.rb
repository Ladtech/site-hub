require 'sitehub/collection/split_route_collection/split.rb'

class SiteHub
  class Collection
    class SplitRouteCollection < Collection
      describe Split do
        describe '#update_value' do
          subject do
            described_class.new(:lower, :upper, :original)
          end

          it 'sets the value to be the out of the supplied block' do
            subject.update_value { :new }
            expect(subject.value).to eq(:new)
          end

          it 'passes the current value to the block' do
            subject.update_value do |value|
              expect(value).to eq(:original)
            end
          end
        end
      end
    end
  end
end
