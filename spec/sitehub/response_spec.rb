class SiteHub
  describe Response do
    subject do
      described_class.new([], 200, {})
    end

    it 'extends Rack::Response' do
      expect(subject).to be_a(Rack::Response)
    end

    describe '#initialize' do
      it 'sets the response time' do
        expect(subject.time).to eq(Time.now)
      end
    end

    describe 'time' do
      it 'returns the same time every time' do
        first_return = subject.time
        expect(subject.time).to eq(first_return)
      end
    end

    describe '#headers' do
      it 'is an alias of header' do
        expect(subject.method(:header)).to eq(subject.method(:headers))
      end
    end
  end
end
