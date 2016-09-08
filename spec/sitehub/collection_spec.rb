require 'sitehub/collection'

class SiteHub
  describe Collection do
    describe '#valid?' do
      it 'must be overiden and raises an exception by default' do
        expect { subject.valid? }.to raise_exception 'implement me'
      end
    end

    describe '#resolve' do
      it 'must be overiden and raises an exception by default' do
        expect { subject.resolve }.to raise_exception 'implement me'
      end
    end

    describe '.inherited' do
      describe '#add' do
        context 'duplicate ids added' do
          subject do
            inheritor = Class.new(described_class) do
              def add(id, value, *_args)
                self[id] = value
              end
            end

            inheritor.new
          end

          it 'raises an error' do
            duplicate = Struct.new(:id).new(1)
            subject.add(duplicate.id, duplicate)
            expected_message = described_class::ClassMethods::UNIQUE_LABELS_MSG
            expect { subject.add(duplicate.id, duplicate) }
              .to raise_exception described_class::DuplicateVersionError, expected_message
          end
        end
      end
    end
  end
end
