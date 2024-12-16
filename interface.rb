require 'sinatra'
require 'json'
require './ExpenseT'
set :views, File.expand_path('./views', settings.root)
get '/' do
  @transactions = ExpenseTracker.new.list_transactions
  erb :index
end
get '/add_transaction' do
  erb :add_transaction
end
post '/add_transaction' do
  amount = params[:amount].to_f
  category = params[:category]
  type = params[:type]
  currency = params[:currency]
  ExpenseTracker.new.add_transaction(amount, category, type, currency)
  redirect to('/')
end

