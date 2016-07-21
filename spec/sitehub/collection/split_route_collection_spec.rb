require 'sitehub/collection/split_route_collection'

class SiteHub
  describe Collection::SplitRouteCollection do
    let(:collection_entry) do
      Class.new do
        include Rules, Resolver

        attr_reader :id

        def initialize(rule = nil, id:)
          @id = id
          @rule = rule
        end
      end
    end

    let(:route_1) { collection_entry.new(id: :id1) }
    let(:route_2) { collection_entry.new(id: :id2) }

    it 'is a collection' do
      expect(subject).to be_a(Collection)
    end

    describe '#[]' do
      context 'key exists' do
      end

      context 'key does not exist' do
      end
    end

    describe '#add' do
      before do
        subject.add route_1.id, route_1, 50
      end
      it 'stores a value' do
        expect(subject[route_1.id]).to be(route_1)
      end

      it 'sets the selection boundary which is used to choose routes' do
        subject.add route_2.id, route_2, 50
        first = subject._values.first
        second = subject._values.last

        expect(first.lower).to eq(0)
        expect(first.upper).to eq(50)

        expect(second.lower).to eq(50)
        expect(second.upper).to eq(100)
      end

      context 'entry is added which takes splits total over 100%' do
        it 'raises an error' do
          expect { subject.add route_2.id, route_2, 101 }
            .to raise_exception described_class::InvalidSplitException, described_class::SPLIT_ERR_MSG
        end
      end

      context 'non fixnum passed in' do
        it 'raises and error' do
          expect { subject.add route_2.id, route_2, 1.1 }
            .to raise_exception described_class::InvalidSplitException, described_class::FIXNUM_ERR_MSG
        end
      end
    end

    describe '#resolve' do
      before do
        subject.add route_1.id, route_1, 50
        subject.add route_2.id, route_2, 50
      end

      context 'rand returns a number within a boundry' do
        it 'it returns the entry with that set of boundaries' do
          expect(subject).to receive(:rand).and_return(15)
          expect(subject.resolve).to eq(route_1)
        end
      end

      context 'rand returns a number equal to the lower boundary of an entry' do
        it 'it returns the entry whos lower boundary is equal to that number' do
          expect(subject).to receive(:rand).and_return(50)
          expect(subject.resolve).to eq(route_2)
        end
      end
    end

    describe '#transform' do
      it "replaces the stores values with what's returned from the block" do
        subject.add route_1.id, route_1, 50
        value_before_transform = subject[route_1.id]
        subject.transform do |value|
          expect(value).to be(value_before_transform)
          :transformed_value
        end

        expect(subject[route_1.id]).to eq(:transformed_value)
      end
    end

    describe '#valid?' do
      context 'splits == to 100' do
        it 'returns true' do
          subject.add route_1.id, route_1, 50
          subject.add route_2.id, route_2, 50
          expect(subject).to be_valid
        end
      end

      context 'splits not == 100' do
        it 'returns false' do
          subject.add route_1.id, route_1, 50
          expect(subject).to_not be_valid
        end
        it 'gives a warning' do
          expect(subject).to receive(:warn).with('splits do not add up to 100% and no default has been specified')
          subject.valid?
        end
      end

      context 'no entries added' do
        it 'returns false' do
          expect(subject).to_not be_valid
        end
      end
    end

    describe '#values' do
      it 'returns values contained inside splits' do
        subject.add route_1.id, route_1, 50
        subject.add route_2.id, route_2, 50
        expect(subject.values).to eq([route_1, route_2])
      end
    end
  end
end
