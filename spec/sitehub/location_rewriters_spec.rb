require 'sitehub/location_rewriters'
class SiteHub
  describe LocationRewriters do
    it 'is an array' do
      expect(subject).to be_kind_of(Array)
    end

    describe '#initialize' do
      context 'hash key is a regexp' do
        it 'leaves the key has a regexp' do
          key = %r{/.*/}
          value = '/'
          expect(described_class.new(key => value)).to eq([LocationRewriter.new(key, value)])
        end
      end

      context 'hash key is a string' do
        it 'converts the key to a regexp' do
          key = 'string'
          value = '/'
          expect(described_class.new(key => value)).to eq([LocationRewriter.new(Regexp.new(key), value)])
        end
      end
    end

    describe '#find' do
      let(:matcher) { Regexp.new('/orders/(.*)') }
      let(:path_template) { '/orders/$1' }
      subject do
        described_class.new(matcher => path_template)
      end
      context 'url matches matcher' do
        it 'returns the path directive' do
          expect(subject.find('http://url.com/orders/123')).to eq(LocationRewriter.new(matcher, path_template))
        end
      end
      context 'url does not match a matcher' do
        it 'returns default matcher' do
          expect(subject.find('http://url.com/mismatch')).to eq(described_class::DEFAULT)
        end
      end
    end
  end
end
