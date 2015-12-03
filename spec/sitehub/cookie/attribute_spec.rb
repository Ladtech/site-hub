class SiteHub
  class Cookie
    describe Attribute do
      let(:attribute_name){'domain'}
      let(:attribute_value){'value'}
      subject do
        described_class.new(attribute_name, attribute_value)
      end
      describe '#initialize' do
        it 'stores the attribute name and its value' do
          expect(subject.name).to eq(attribute_name.to_sym)
          expect(subject.value).to eq(attribute_value)
        end

        it 'sanitises the string parameter' do
          expect(described_class.new("#{attribute_name} \n", attribute_value).name).to eq(attribute_name.to_sym)
        end
      end

      describe '#to_s' do
        it 'contains the attribute name and value' do
          expect(subject.to_s).to eq("#{attribute_name}=#{attribute_value}")
        end
      end
    end
  end
end