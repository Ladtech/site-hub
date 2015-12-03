require 'sitehub/resolver'
class SiteHub
  describe Resolver do
    subject do
      Object.new.tap do |o|
        o.extend(described_class)
      end
    end
    describe '#resolve' do
      it 'returns self' do
        expect(subject.resolve).to be(subject)
      end
    end
  end
end