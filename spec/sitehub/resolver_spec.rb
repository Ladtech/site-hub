require 'sitehub/resolver'
class SiteHub
  describe Resolver do
    include_context :module_spec

    describe '#resolve' do
      it 'returns self' do
        expect(subject.resolve).to be(subject)
      end
    end
  end
end
