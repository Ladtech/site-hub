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

      it 'puts the SiteHub request in to env' do
        get('/')
        env = last_request.env
        expect(env[REQUEST]).to eq(Request.new(env: env, mapped_path: nil, mapped_url: nil))
      end
    end
  end
end
