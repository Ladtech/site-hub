shared_context :rack_test do
  include Rack::Test::Methods

  def env
    @env ||= {}
  end

  before :each do |example|
    @env = { 'async.callback' => callback } if example.metadata[:async]
  end
end
