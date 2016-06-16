require 'sitehub/memoize'
class SiteHub
  describe Memoize do
    context :module_spec

    subject do
      clazz = Class.new do
        extend Memoize

        def helper(*args)
          result = block_given? ? yield : nil
          [args, result].flatten.compact
        end
        memoize :helper
      end
      clazz.new
    end

    describe '#memoize' do
      it 'memoizes the return of the given method' do
        result = subject.helper
        expect(result).to be(subject.helper)
      end

      context 'args passed' do
        it 'sends them to the memoized method' do
          expect(subject.helper(:arg1, :arg2)).to eq([:arg1, :arg2])
        end
      end

      context 'block passed' do
        it 'sends the block to the memoized method' do
          block = proc { :block_called }
          expect(subject.helper(&block)).to eq([:block_called])
        end
      end
    end
  end
end
