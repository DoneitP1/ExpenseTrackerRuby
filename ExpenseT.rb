require 'json'
require 'bcrypt'
class User
  attr_accessor :username, :password
  USERS_FILE = 'users.json'
  def initialize(username, password)
    @username = username
    @password = BCrypt::Password.create(password)
  end
  def authenticate(password)
    BCrypt::Password.new(@password) == password
  end
  def to_h
    { username: @username, password: @password }
  end
  def self.from_h(hash)
    new(hash["username"], hash["password"])
  end
  def self.load_users
    return [] unless File.exist?(USERS_FILE)
    JSON.parse(File.read(USERS_FILE)).map { |hash| from_h(hash) }
  end
  def self.save_users(users)
    File.write(USERS_FILE, JSON.pretty_generate(users.map(&:to_h)))
  end
end
class Transaction
  attr_accessor :amount, :category, :type, :date, :currency
  CURRENCY_LIST = ['USD', 'EUR', 'GBP', 'JPY', 'AUD', 'CAD', 'INR', 'TRY']
  CATEGORY_LIST = ['Food', 'Rent', 'Travel', 'Entertainment', 'Health', 'Utilities']
  def initialize(amount, category, type, currency = 'USD')
    @amount = amount
    @category = category
    @type = type
    @date = Time.now.strftime("%Y-%m-%d")
    @currency = currency
  end
  def to_h
    { amount: @amount, category: @category, type: @type, date: @date, currency: @currency }
  end
  def self.from_h(hash)
    new(hash["amount"], hash["category"], hash["type"], hash["currency"]).tap { |t| t.date = hash["date"] }
  end
  def to_s
    "#{@date}: #{@type.capitalize} - #{@category}: #{@amount} #{@currency}"
  end
  def self.valid_category?(category)
    CATEGORY_LIST.include?(category) || category.length > 0
  end
  def self.valid_currency?(currency)
    CURRENCY_LIST.include?(currency)
  end
end
class ExpenseTracker
  attr_reader :current_user
  def initialize(current_user)
    @current_user = current_user
    @transactions = load_transactions
  end
  def add_transaction(amount, category, type, currency)
    return unless valid_transaction?(amount, category, currency)
    transaction = Transaction.new(amount, category, type, currency)
    @transactions << transaction
    save_transactions
    puts "Transaction added successfully!"
  end

  def view_summary
    income = @transactions.select { |t| t.type == 'income' }.sum(&:amount)
    expenses = @transactions.select { |t| t.type == 'expense' }.sum(&:amount)
    puts "\n--- Summary ---"
    puts "Total Income: #{income} USD"
    puts "Total Expenses: #{expenses} USD"
    puts "Net Balance: #{income - expenses} USD"
  end

  def list_transactions
    if @transactions.empty?
      puts "No transactions found."
    else
      puts "\n--- Transactions ---"
      @transactions.each_with_index { |t, idx| puts "#{idx + 1}. #{t}" }
    end
  end

  private

  def load_transactions
    user_file = "#{current_user.username}_transactions.json"
    return [] unless File.exist?(user_file)
    JSON.parse(File.read(user_file)).map { |hash| Transaction.from_h(hash) }
  end

  def save_transactions
    user_file = "#{current_user.username}_transactions.json"
    File.write(user_file, JSON.pretty_generate(@transactions.map(&:to_h)))
  end

  def valid_transaction?(amount, category, currency)
    if amount <= 0
      puts "Amount must be positive."
      return false
    elsif !Transaction.valid_category?(category)
      puts "Invalid category. Please select one from: #{Transaction::CATEGORY_LIST.join(', ')}."
      return false
    elsif !Transaction.valid_currency?(currency)
      puts "Invalid currency. Supported currencies: #{Transaction::CURRENCY_LIST.join(', ')}."
      return false
    end
    true
  end
end

# CLI class for user interaction
class ExpenseTrackerCLI
  def initialize
    @users = User.load_users
    @current_user = nil
    @tracker = nil
    login_or_register
  end

  def start
    return unless @current_user
    loop do
      display_menu
      choice = gets.chomp.to_i
      handle_choice(choice)
      break if choice == 6
    end
  end

  private

  def display_menu
    puts "\n--- Expense Tracker Menu ---"
    puts "1. Add Income"
    puts "2. Add Expense"
    puts "3. View Transactions"
    puts "4. View Summary"
    puts "5. Log Out"
    puts "6. Exit"
    print "Choose an option: "
  end

  def handle_choice(choice)
    case choice
    when 1 then add_transaction('income')
    when 2 then add_transaction('expense')
    when 3 then @tracker.list_transactions
    when 4 then @tracker.view_summary
    when 5 then log_out
    when 6 then puts "Goodbye!"
    else puts "Invalid option, try again."
    end
  end

  def add_transaction(type)
    print "Enter amount (USD): "
    amount = gets.chomp.to_f
    category = get_category
    currency = get_currency
    @tracker.add_transaction(amount, category, type, currency)
  end

  def get_category
    puts "Select a category:"
    Transaction::CATEGORY_LIST.each_with_index { |cat, idx| puts "#{idx + 1}. #{cat}" }
    print "Enter custom category if needed: "
    gets.chomp
  end

  def get_currency
    puts "Select a currency:"
    Transaction::CURRENCY_LIST.each_with_index { |currency, idx| puts "#{idx + 1}. #{currency}" }
    choice = gets.chomp.to_i
    Transaction::CURRENCY_LIST[choice - 1] || 'USD'
  end

  def login_or_register
    loop do
      puts "--- Welcome to Expense Tracker ---"
      print "1. Login\n2. Register\n3. Exit\nChoose an option: "
      choice = gets.chomp.to_i
      case choice
      when 1 then login
      when 2 then register
      when 3 then exit
      else puts "Invalid choice, try again."
      end
      break if @current_user
    end
  end

  def login
    print "Username: "
    username = gets.chomp
    print "Password: "
    password = gets.chomp
    user = @users.find { |user| user.username == username }

    if user && user.authenticate(password)
      @current_user = user
      @tracker = ExpenseTracker.new(@current_user)
      puts "Login successful!"
    else
      puts "Invalid credentials, try again."
    end
  end

  def register
    print "Enter a new username: "
    username = gets.chomp
    print "Enter a new password: "
    password = gets.chomp

    if @users.any? { |user| user.username == username }
      puts "Username already exists. Please choose another one."
    else
      user = User.new(username, password)
      @users << user
      User.save_users(@users)
      @current_user = user
      @tracker = ExpenseTracker.new(@current_user)
      puts "Registration successful!"
    end
  end
  def log_out
    puts "Logging out..."
    @current_user = nil
    @tracker = nil
  end
end
ExpenseTrackerCLI.new.start
