require 'sitehub/location_rewriter'
class SiteHub
  describe LocationRewriter do
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
        described_class.new(Regexp.new('http://www.downstream.com/orders/(.*)'), '/$1')
      end

      let(:url) { 'http://www.downstream.com/orders/123' }
      let(:source_url_base) { 'http://www.upstream.com' }
      let(:source_url) { "#{source_url_base}/some/where/123" }

      it 'uses the url to populate the path template' do
        expect(subject.apply(url, source_url)).to eq("#{source_url_base}/123")
      end

      it 'retains the query string' do
        expect(subject.apply("#{url}?param=value", source_url)).to eq("#{source_url_base}/123?param=value")
      end

      it 'leaves path template unchanged' do
        before = subject.path_template.dup
        subject.apply("#{url}?param=value", source_url)
        expect(subject.path_template).to eq(before)
      end
    end
  end
end
