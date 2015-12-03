require 'sitehub/transaction_id'

class SiteHub
  describe TransactionId do
    let(:transaction_id){Constants::RackHttpHeaderKeys::TRANSACTION_ID}
    subject do
      described_class.new(Proc.new{})
    end
    it 'adds a unique identifier to the request' do
      uuid = UUID.generate(:compact)
      expect(UUID).to receive(:generate).with(:compact).and_return(uuid)
      env = {}
      subject.call(env)

      expect(env[transaction_id]).to eq(uuid)
    end

    context 'transaction id header already exists' do
      it 'leaves it intact' do
        expect(UUID).to_not receive(:generate)
        env = {transaction_id => :exiting_id}
        subject.call(env)

        expect(env[transaction_id]).to eq(:exiting_id)
      end
    end
  end
end
