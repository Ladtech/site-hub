require 'sitehub/forward_proxy'
class SiteHub
  describe ForwardProxy do
    let(:mapped_path) { '/mapped_path' }
    let(:mapped_url) { 'http://www.somewhere.com/' }

    subject(:app) do
      described_class.new(sitehub_cookie_name: :cookie_name,
                          id: :id,
                          mapped_path: mapped_path,
                          mapped_url: mapped_url)
    end

    before do
      stub_request(:get, mapped_url).to_return(body: 'body')
    end

    it 'includes Resolver' do
      expect(app).to be_a(Resolver)
    end

    it 'includes Rules' do
      expect(app).to be_a(Rules)
    end

    describe '#call' do
      it 'calls the app' do
        get(mapped_path)
        expect(last_response.status).to eq(200)
      end

      it 'stores the SiteHub request definition in env' do
        get(mapped_path)

        expected_request = Request.new(env: last_request.env,
                                       mapped_url: mapped_url,
                                       mapped_path: mapped_path)

        expect(last_request.env[REQUEST]).to eq(expected_request)
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
            described_class.new(id: :id,
                                sitehub_cookie_path: expected_path,
                                sitehub_cookie_name: :cookie_name,
                                mapped_path: mapped_path,
                                mapped_url: mapped_url)
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
