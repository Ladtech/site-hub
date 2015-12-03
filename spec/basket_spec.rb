class Basket

  attr_reader :items
  def initialize shopping_list
    @items = parse(shopping_list)
  end

  def parse shopping_list
    shopping_list.lines[1..-1].collect { |item|
      item.chomp.to_sym
    }
  end
end

describe Basket do

  describe '#initialize' do
    it 'takes a shopping list' do

      shopping_list=<<LIST
list
apple
carrot
LIST

      basket = described_class.new(shopping_list)
      expect(basket.items).to eq([:apple, :carrot])
    end
  end
end