require 'sitehub/middleware/transaction_id'

class SiteHub
  module Middleware
    describe TransactionId do
      let(:transaction_id) { Constants::HttpHeaderKeys::TRANSACTION_ID }
      subject do
        described_class.new(proc {})
      end

      let(:request) { Request.new(env: {}) }
      let(:env) { { REQUEST => request } }

      it 'adds a unique identifier to the request' do
        uuid = UUID.generate(:compact)
        expect(UUID).to receive(:generate).with(:compact).and_return(uuid)
        subject.call(env)

        expect(request.headers[transaction_id]).to eq(uuid)
      end

      context 'transaction id header already exists' do
        it 'leaves it intact' do
          expect(UUID).to_not receive(:generate)
          request.headers[transaction_id] = :existing_id
          subject.call(env)

          expect(request.headers[transaction_id]).to eq(:existing_id)
        end
      end
    end
  end
end
