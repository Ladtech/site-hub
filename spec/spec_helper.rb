require 'rspec'
require 'rack/test'
require 'webmock/rspec'
$LOAD_PATH.unshift("#{__dir__}/..", "#{__dir__}/support")

require 'support/shared_contexts'
require 'support/shared_examples'
require 'support/silent_warnings'

require 'support/patch/rack/response'

if ENV['coverage'] == 'true'
  require 'simplecov'
  SimpleCov.start do
    add_filter '/spec/'
  end
end

require 'lib/sitehub'

RSpec.configure do |config|
  include Rack::Test::Methods
  config.before do
    WebMock.enable!
  end

  config.after(:suite) do
    WebMock.disable!
  end
end
