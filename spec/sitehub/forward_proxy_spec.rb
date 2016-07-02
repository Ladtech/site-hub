require 'sitehub/forward_proxy'
class SiteHub
  describe ForwardProxy do
    let(:mapped_path) { '/mapped_path' }
    let(:mapped_url) { 'http://www.somewhere.com/' }

    include_context :rack_request

    subject(:app) do
      described_class.new(mapped_path: mapped_path,
                          mapped_url: mapped_url)
    end

    before do
      stub_request(:get, mapped_url).to_return(body: 'body')
    end

    describe '#call' do
      let(:rack_headers) { {} }
      let(:request) { Request.new(env: env_for(path: mapped_path, env: rack_headers)) }

      before do
        get(mapped_path, {}, REQUEST => request)
      end

      it 'calls the app' do
        expect(last_response.status).to eq(200)
      end

      it 'maps the request' do
        request = last_request.env[REQUEST]
        expect(request.mapped_path).to eq(mapped_path)
        expect(request.mapped_url).to eq(mapped_url)
      end
    end
  end
end
