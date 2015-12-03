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

      let(:url){'http://www.upstream.com/orders/123'}

      it 'uses the url to populate the path template' do
        expect(subject.apply(url)).to eq('/123')
      end

      it 'retains the query string' do
        expect(subject.apply("#{url}?param=value")).to eq('/123?param=value')
      end
    end

    describe '#path_template' do
      it 'returns a duplicate of the path_template every time' do
        version1, version2 = subject.path_template, subject.path_template
        expect(version1).to eq(version2)
        expect(version1).to_not be(version2)
      end
    end

  end

end