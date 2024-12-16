require 'sinatra'
require_relative 'ExpenseT'

enable :sessions
set :views, File.join(File.dirname(__FILE__), 'views')

get '/' do
  if session[:username]
    current_user = User.load_users.find { |u| u.username == session[:username] }
    @tracker = ExpenseTracker.new(current_user)
    @transactions = @tracker.list_transactions
    erb :index
  else
    redirect '/login'
  end
end

get '/login' do
  erb :login
end

post '/login' do
  username = params[:username]
  password = params[:password]

  users = User.load_users
  user = users.find { |u| u.username == username && u.authenticate(password) }

  if user
    session[:username] = username
    redirect '/'
  else
    @error = "Invalid username or password."
    erb :login
  end
end

get '/logout' do
  session.clear
  redirect '/login'
end

