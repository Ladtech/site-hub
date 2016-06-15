require 'sitehub/path_directive'
class SiteHub
  describe PathDirective do
    subject do
      described_class.new(%r{/match}, '/path_template')
    end

    describe '#match?' do
      context 'matcher applies' do
        it 'returns true' do
          expect(subject.match?('/match')).to eq(true)
        end
      end

      context 'matcher does not apply' do
        it 'returns false' do
          expect(subject.match?('/mismatch')).to eq(false)
        end
      end
    end

    describe '#apply' do
      subject do
        described_class.new(Regexp.new('http://www.upstream.com/orders/(.*)'), '/$1')
      end

      let(:url) { 'http://www.upstream.com/orders/123' }

      it 'uses the url to populate the path template' do
        expect(subject.apply(url)).to eq('/123')
      end

      it 'retains the query string' do
        expect(subject.apply("#{url}?param=value")).to eq('/123?param=value')
      end
    end

    describe '#path_template' do
      it 'returns a duplicate of the path_template every time' do
        first_version = subject.path_template
        second_version = subject.path_template
        expect(first_version).to eq(second_version)
        expect(first_version).to_not be(second_version)
      end
    end
  end
end
