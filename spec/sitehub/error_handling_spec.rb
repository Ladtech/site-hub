describe 'error handling' do
  include_context :site_hub
  include_context :async

  before do
    WebMock.enable!
  end
  context 'connectivity error' do
    def app
      @app ||= Async::Middleware.new(rack_application)
    ensure
      WebMock.disable!
    end

    it 'shows the error page when an exception occurs' do
      get('/endpoint')
      expect(last_response.status).to eq(500)
    end
  end
end
