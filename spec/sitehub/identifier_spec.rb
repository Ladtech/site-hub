class SiteHub
  describe Identifier do
    describe '#generate_label' do
      context 'id' do
        subject do
          described_class.new(id: :parent_id,
                              sitehub_cookie_name: :cookie_name,
                              mapped_path: '/path')
        end
        it 'it returns a concatenated id' do
          expect(subject.generate_label(:label)).to eq("#{:parent_id}|#{:label}")
        end
      end

      context 'id not set' do
        it 'it returns the given value' do
          expect(subject.generate_label(:label)).to eq(:label)
        end
      end
    end
  end
end