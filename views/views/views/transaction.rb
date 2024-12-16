

class Transaction
  attr_accessor :amount, :category, :type, :date, :currency

  def initialize(amount, category, type, currency)
    @amount = amount
    @category = category
    @type = type
    @currency = currency
    @date = Time.now.strftime("%Y-%m-%d")
  end

  def to_h
    { amount: @amount, category: @category, type: @type, date: @date, currency: @currency }
  end

  def self.from_h(hash)
    transaction = Transaction.new(hash["amount"], hash["category"], hash["type"], hash["currency"])
    transaction.date = hash["date"]
    transaction
  end
end


