require 'sitehub/middleware'
class SiteHub
  describe Middleware do
    include_context :middleware_test, :module_spec
    include_context :module_spec

    describe '#use' do
      it 'stores the middleware to be used by the forward proxies' do
        block = proc {}
        args = [:args]
        subject.use :middleware, *args, &block
        expect(subject.middlewares).to eq([[:middleware, args, block]])
      end
    end

    describe '#middleware?' do
      context 'middleware defined' do
        it 'returns true' do
          subject.use :middleware
          expect(subject.middleware?).to eq(true)
        end
      end

      context 'no middleware defined' do
        it 'returns true' do
          expect(subject.middleware?).to eq(false)
        end
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
          first_middleware = create_middleware
          second_middleware = create_middleware
          subject.use first_middleware
          subject.use second_middleware

          result = subject.apply_middleware(:app)

          expect(result).to be_a(first_middleware)
          expect(result).to be_using(second_middleware)
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
