require 'json'
class Transaction
  attr_accessor :amount, :category, :type, :date
  def initialize(amount, category, type)
    @amount = amount
    @category = category
    @type = type
    @date = Time.now.strftime("%Y-%m-%d")
  end
  def to_h
    { amount: @amount, category: @category, type: @type, date: @date }
  end
  def self.from_h(hash)
    transaction = Transaction.new(hash["amount"], hash["category"], hash["type"])
    transaction.date = hash["date"]
    transaction
  end
  def to_s
    "#{@date}: #{@type.capitalize} - #{@category}: #{@amount} USD"
  end
end
class ExpenseTracker
  DATA_FILE = 'transactions.json'
  def initialize
    @transactions = load_transactions
  end
  def add_transaction(amount, category, type)
    transaction = Transaction.new(amount, category, type)
    @transactions << transaction
    save_transactions
    puts "Transaction added successfully!"
  end
  def view_summary
    income = @transactions.select { |t| t.type == 'income' }.sum(&:amount)
    expenses = @transactions.select { |t| t.type == 'expense' }.sum(&:amount)
    puts "\nSummary:"
    puts "Total Income: #{income} USD"
    puts "Total Expenses: #{expenses} USD"
    puts "Net Balance: #{income - expenses} USD"
  end
  def list_transactions
    puts "\nTransactions:"
    if @transactions.empty?
      puts "No transactions found."
    else
      @transactions.each_with_index do |transaction, idx|
        puts "#{idx + 1}. #{transaction}"
      end
    end
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
class ExpenseTrackerCLI
  def initialize
    @tracker = ExpenseTracker.new
  end
  def start
    loop do
      puts "\n--- Expense Tracker Menu ---"
      puts "1. Add Income"
      puts "2. Add Expense"
      puts "3. View Transactions"
      puts "4. View Summary"
      puts "5. Exit"
      print "Choose an option: "
      case gets.chomp.to_i
      when 1 then add_transaction('income')
      when 2 then add_transaction('expense')
      when 3 then @tracker.list_transactions
      when 4 then @tracker.view_summary
      when 5
        puts "Goodbye!"
        break
      else
        puts "Invalid option. Please try again."
      end
    end
  end
  private
  def add_transaction(type)
    print "Enter amount (USD): "
    amount = gets.chomp.to_f
    print "Enter category (e.g., Food, Rent, Travel): "
    category = gets.chomp
    @tracker.add_transaction(amount, category, type)
  end
end
ExpenseTrackerCLI.new.start