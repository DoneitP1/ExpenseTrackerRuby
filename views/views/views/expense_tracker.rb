class ExpenseTracker
  DATA_FILE = 'transactions.json'
  def initialize
    @transactions = load_transactions
  end
  def add_transaction(amount, category, type, currency)
    transaction = Transaction.new(amount, category, type, currency)
    @transactions << transaction
    save_transactions
  end
  def list_transactions
    @transactions
  end
  private
  def save_transactions
    File.write(DATA_FILE, JSON.pretty_generate(@transactions.map(&:to_h)))
  end
  def load_transactions
    if File.exist?(DATA_FILE)
      JSON.parse(File.read(DATA_FILE)).map { |hash| Transaction.from_h(hash) }
    else
      []
    end
  end
end