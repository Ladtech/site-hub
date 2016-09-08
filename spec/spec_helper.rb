require 'rspec'
require 'rack/test'
require 'webmock/rspec'
require 'timecop'
$LOAD_PATH.unshift("#{__dir__}/..", "#{__dir__}/support")
require 'async/middleware'

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
    Timecop.freeze
    WebMock.enable!
  end

  config.after do
    Timecop.return
  end

  config.after(:suite) do
    WebMock.disable!
  end
end
