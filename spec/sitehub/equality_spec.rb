class SiteHub
  describe Equality do
    subject(:test_class) do
      Class.new do
        include Equality

        def initialize(first_attribute, second_attribute)
          @first_attribute = first_attribute
          @second_attribute = second_attribute
        end
      end
    end
    subject do
      test_class.new(:foo, :bar)
    end

    describe '#==' do
      context 'match' do
        it 'returns true' do
          match = test_class.new(:foo, :bar)
          expect(subject).to eq(match)
        end
      end
      context 'mismatch' do
        it 'returns false' do
          match = test_class.new(:wrong, :bar)
          expect(subject).to_not eq(match)
        end
      end
    end
  end
end
