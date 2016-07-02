require 'sitehub/nil_route'
class SiteHub
  describe NilRoute do
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
