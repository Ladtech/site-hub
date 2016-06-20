require 'sitehub/location_rewriters_spec'
class SiteHub
  describe NilLocationRewriter do
    describe 'apply' do
      it 'returns the location parameter' do
        expect(subject.apply(:location, :source_url)).to eq(:location)
      end
    end
  end
end
