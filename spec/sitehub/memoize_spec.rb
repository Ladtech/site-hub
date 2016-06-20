require 'sitehub/memoize'
class SiteHub
  describe Memoize do
    context :module_spec

    let(:test_class) do
      Class.new do
        extend Memoize

        def helper(*args)
          result = block_given? ? yield : nil
          [args, result].flatten.compact
        end
        memoize :helper
      end
    end

    subject do
      test_class.new
    end

    describe '#memoize' do
      it 'memoizes the return of the given method' do
        result = subject.helper
        expect(result).to be(subject.helper)
      end

      context 'method name has a ? in it' do
        it 'memoizes the return of the given method' do
          test_class.class_eval do
            def true?
              'answer'
            end
            memoize :true?
          end

          result = subject.true?
          expect(result).to be(subject.true?)
        end
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
