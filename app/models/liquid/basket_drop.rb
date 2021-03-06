class Liquid::BasketDrop < Liquid::Drop
  def initialize(basket)
    @basket = basket
  end

  def delivery
    Liquid::DeliveryDrop.new(@basket.delivery)
  end

  def description
    @basket.description
  end
end
