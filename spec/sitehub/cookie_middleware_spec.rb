require 'sitehub/cookie_middleware'
class SiteHub
  describe CookieMiddleware do

    let(:mapped_path){'/mapped_path'}

    subject(:app) do
      app = proc { [200, {}, []] }
      described_class.new(app, sitehub_cookie_name: :cookie_name, id: :id)
    end

    it 'includes Resolver' do
      expect(app).to be_a(Resolver)
    end

    it 'includes Rules' do
      expect(app).to be_a(Rules)
    end

    describe '#call' do

      it 'calls the app' do
        get('/')
        expect(last_response.status).to eq(200)
      end

      context 'recorded routes cookie' do

        it 'drops a cookie using the name of the sitehub_cookie_name containing the id' do
          get(mapped_path)
          expect(last_response.cookies[:cookie_name.to_s]).to eq(value: :id.to_s, path: mapped_path)
        end

        context 'recorded_routes_cookie_path not set' do
          it 'sets the path to be the request path' do
            get(mapped_path, {})
            expect(last_response.cookies[:cookie_name.to_s][:path]).to eq(mapped_path)
          end
        end

        context 'recorded_routes_cookie_path set' do
          let(:expected_path) { '/expected_path' }

          subject(:app) do
            app = proc { [200, {}, []] }
            described_class.new(app,
                                id: :id,
                                sitehub_cookie_path: expected_path,
                                sitehub_cookie_name: :cookie_name)
          end

          it 'is set as the path' do
            get(mapped_path, {})
            expect(last_response.cookies[:cookie_name.to_s][:path]).to eq(expected_path)
          end
        end
      end

    end
  end
end