shared_context :rack_http_request do
  def env_for(path:, method: :get, params: {}, body: nil, env: {})
    env = env.merge(method: method, params: (body || params))
    Rack::Test::Session.new(nil).send(:env_for, path, env)
  end
end
