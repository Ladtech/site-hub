require 'sitehub/middleware'
class SiteHub
  describe Middleware do
    include_context :middleware_test

    subject do
      Object.new.tap do |o|
        o.extend(described_class)
      end
    end

    describe '#use' do
      it 'stores the middleware to be used by the forward proxies' do
        block = proc {}
        args = [:args]
        subject.use :middleware, *args, &block
        expect(subject.middlewares).to eq([[:middleware, args, block]])
      end
    end

    describe '#apply_middleware' do
      context 'middleware defined' do
        it 'wraps the supplied app in the middleware' do
          subject.use middleware
          result = subject.apply_middleware(:app)
          expect(result).to be_a(middleware)
          expect(result.app).to eq(:app)
        end

        it 'wraps the supplied app in the middleware in the order they were supplied' do
          middleware_1 = create_middleware
          middleware_2 = create_middleware
          subject.use middleware_1
          subject.use middleware_2

          result = subject.apply_middleware(:app)

          expect(result).to be_a(middleware_1)
          expect(result).to be_using(middleware_2)
        end

        context 'args supplied' do
          it 'passes the arg to the middleware' do
            subject.use middleware, :arg
            result = subject.apply_middleware(:app)
            expect(result.arg).to eq(:arg)
          end
        end

        context 'block supplied' do
          it 'passes the block to the middleware' do
            block_passed = false

            subject.use middleware do
              block_passed = true
            end

            subject.apply_middleware(:app)
            expect(block_passed).to be(true)
          end
        end
      end
    end
  end
end
