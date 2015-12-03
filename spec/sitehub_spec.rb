describe SiteHub do

  describe '::build' do
    it 'gives you a configure sitehub to run in your config.ru' do
      allow_any_instance_of(SiteHub::Builder).to receive(:build).and_return(:sitehub)
      expect(described_class.build).to eq(:sitehub)
    end
    it 'passes your block on a sitehub builder' do
      block_called = false
      block = Proc.new do
        block_called = true
      end

      described_class.build(&block)
      expect(block_called).to eq(true)
    end

  end
end