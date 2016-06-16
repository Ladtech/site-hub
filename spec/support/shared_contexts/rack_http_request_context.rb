shared_context :rack_http_request do
  def env_for(path: '/', method: :get, params_or_body: {}, env: {})
    env = env.merge(method: method, params: params_or_body)
    Rack::Test::Session.new(nil).send(:env_for, path, env)
  end
end
