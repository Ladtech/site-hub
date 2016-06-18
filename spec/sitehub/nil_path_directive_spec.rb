require 'sitehub/nil_path_directive'
class SiteHub
  describe NilPathDirective do
    describe 'apply' do
      it 'returns the location parameter' do
        expect(subject.apply(:location, :source_url)).to eq(:location)
      end
    end
  end
end