require 'sitehub/cookie'

class SiteHub
  describe Cookie do
    let(:attribute_class) { described_class::Attribute }
    let(:flag_class) { described_class::Flag }
    let(:domain_attribute) { attribute_class.new(:domain.to_s, 'example.com') }
    let(:name) { 'sitehub.recorded_route' }
    let(:value) { 'new' }
    let(:cookie_string) { "#{name}=#{value}; HttpOnly; #{domain_attribute}" }

    subject do
      described_class.new cookie_string
    end

    describe '#initialize' do
      it 'parse a cookie string in to attributes and flags' do
        expect(subject.attributes_and_flags).to eq([flag_class.new('HttpOnly'), domain_attribute])
      end

      it 'extracts name as a symbol' do
        expect(subject.name).to eq('sitehub.recorded_route'.to_sym)
      end

      it 'extracts the value' do
        expect(subject.value).to eq('new')
      end
    end

    describe '#find' do
      context 'entry found' do
        it 'returns the entry with the given name' do
          expect(subject.find(:domain)).to eq(domain_attribute)
        end
      end

      context 'entry not found' do
        it 'returns nil' do
          expect(subject.find(:missing)).to eq(nil)
        end
      end
    end

    describe '#to_s' do
      it 'prints the attributes and flags' do
        expect(subject.to_s).to eq(cookie_string)
      end
    end
  end
end
