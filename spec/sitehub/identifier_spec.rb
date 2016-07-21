class SiteHub
  describe Identifier do
    subject(:valid_identifer) do
      described_class.new(:root_id)
    end

    subject(:blank) do
      described_class.new(nil)
    end

    describe '#initialize' do
      context 'id supplied' do
        it 'it returns a concatenated id' do
          expect(valid_identifer.child_label(:label)).to eq('root_id|label')
        end
      end

      context 'id not set' do
        it 'it returns the given value' do
          expect(blank.child_label(:label)).to eq(:label)
        end
      end
    end

    describe '#valid?' do
      context 'has at least one component' do
        it 'returns true' do
          expect(valid_identifer).to be_valid
        end
      end

      context 'does not have at least one component' do
        it 'returns false' do
          expect(blank).to_not be_valid
        end
      end
    end

    describe '#sub_id' do
      context 'id contains more than one pipe seperated value' do
        subject do
          described_class.new('root|first|second')
        end

        it 'removes the first value in the list' do
          expect(subject.sub_id).to eq(:'first|second')
        end

        it 'returns an object of type Identifier' do
          expect(subject.sub_id).to be_a(described_class)
        end
      end
    end

    describe '#to_s' do
      subject do
        described_class.new(:root_id)
      end
      it 'returns the id as a string' do
        expect(valid_identifer.to_s).to eq(:root_id.to_s)
      end
    end

    describe '#to_sym' do
      it 'returns the id as a string' do
        expect(valid_identifer.to_sym).to eq(:root_id)
      end
    end

    describe '#==' do
      subject do
        described_class.new(:root_id)
      end

      context 'other can be converted to a matching symbol' do
        it 'returns true' do
          expect(subject).to eq(:root_id)
          expect(subject).to eq('root_id')
        end
      end

      context 'other can not be converted to a matching symbol' do
        it 'returns true' do
          expect(subject).to_not eq('different')
        end
      end
    end
  end
end
