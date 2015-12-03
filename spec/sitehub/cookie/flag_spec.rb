class SiteHub
  class Cookie
    describe Flag do
      let(:name) { 'flag' }
      let(:string_sanitiser){Object.new.tap{|o|o.extend(StringSanitiser)}}
      subject do
        described_class.new(name)
      end

      describe '#initialize' do
        it 'stores the value as a symbol' do
          expect(subject.name).to eq(name.to_sym)
        end

        it 'sanitises the string parameter' do
          expect(described_class.new("#{name} \n").name).to eq(name.to_sym)
        end
      end

      describe '#to_s' do
        it 'returns the name' do
          expect(subject.to_s).to eq(name)
        end
      end
    end
  end
end