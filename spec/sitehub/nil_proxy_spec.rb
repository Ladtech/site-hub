require 'sitehub/nil_proxy'
class SiteHub
  describe NilProxy do
    describe '#call' do
      let(:app) do
        described_class.new
      end

      it 'returns a 404' do
        expect(get('/').status).to eq(404)
      end
    end
  end
end
