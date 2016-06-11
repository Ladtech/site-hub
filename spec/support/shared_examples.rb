shared_examples 'prohibited_header_filter' do
  let(:permitted_header) { 'permitted-header' }

  describe 'treatment of headers according to RFC2616: 13.5.1 and RFC2616: 14.10' do
    context 'prohibitted headers' do
      it 'filters them out' do
        expect(subject).to_not have_prohibitted_headers
      end
    end

    it 'filters out hop by hop headers identified in connection header' do
      expect(subject).to include_headers(permitted_header)
      expect(subject).not_to include_headers(hop_header_1, hop_header_2)
    end
  end
end
