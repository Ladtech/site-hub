

shared_context :integration do
  unless const_defined?(:CONFIG_SERVER_URL)
    CONFIG_SERVER_URL = 'http://the.config.server'.freeze
    DOWNSTREAM_URL = 'http://downstream.url'.freeze
    ERROR_LOGGER = StringIO.new
    ACCESS_LOGGER = StringIO.new
  end

  def sitehub(&block)
    builder_block = proc do
      access_logger ACCESS_LOGGER
      error_logger ERROR_LOGGER
      instance_eval(&block)
    end
    SiteHub.build(&builder_block)
  end
end
