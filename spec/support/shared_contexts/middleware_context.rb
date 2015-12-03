shared_context :middleware_test do

  include_context :rack_test

  let(:inner_app){
    proc{[200, {}, []]}
  }

  subject(:app) do
    described_class.new(inner_app)
  end

  def collect_middleware rack_app
    middleware = [rack_app]
    while rack_app = rack_app.instance_variable_get(:@app)
      middleware << rack_app
    end
    middleware
  end


  def find_middleware rack_app, clazz
    return rack_app if rack_app.is_a?(clazz)
    collect_middleware(rack_app).find{|middleware| middleware.is_a?(clazz)}
  end

  RSpec::Matchers.define :be_using do |expected, *args|
    match do |actual|
      !!find_middleware(actual, expected)
    end
  end

  def create_middleware
    Class.new do
      attr_reader :app, :arg
      def initialize app, arg=nil, &block
        @app, @arg = app, arg
        block.call if block
      end

      def call env
        @app.call env
      end
    end

  end

  let(:middleware) do
    create_middleware
  end
end