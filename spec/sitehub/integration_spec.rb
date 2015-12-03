describe 'proxying calls' do
  include_context :site_hub
  include_context :async

  describe 'supported HTTP verbs' do

    before do
      WebMock.enable!
    end

    let(:app){async_middleware.new(rack_application)}

    %i(get post put delete).each do |verb|
      it "forwards the downstream" do
        stub_request(verb, downstream_url).to_return(:body => 'hello')
        send(verb, '/endpoint')
        expect(app.last_response.body).to eq(['hello'])
      end
    end
  end
end