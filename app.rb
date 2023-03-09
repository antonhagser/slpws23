require 'sinatra'
require 'slim'
require 'sqlite3'

enable :sessions

require_relative 'models/user'
require_relative 'models/product'
require_relative 'models/bid'

require_relative 'backend/auth'
require_relative 'backend/product'

db = SQLite3::Database.new('./db/marketplace.sqlite')
db.execute('DELETE FROM bids')
db.execute('DELETE FROM products')
db.execute('DELETE FROM users')
db.execute('VACUUM')

user = User.new('StarToLeft', Auth.encrypt_password('sdn72@£x81'), nil, Time.now, 'anton.hagser@epsidel.se')
user.insert

puts 'Auth result: ' + Auth.authenticate(user, 'sdn72@£x81').to_s
puts 'Auth result: ' + Auth.authenticate(user, 'sdn72@£x82').to_s

creation_date = Time.now
# expiration_date = creation_date + (5 * 24 * 60 * 60)
expiration_date = creation_date + 1
product = Product.new(user.id, 'Test', 'This is a test', creation_date, expiration_date, false, nil, nil)
product.insert

product1 = Product.find(product.id)
puts product1.title

user1 = User.find(user.id)
puts user1.username

# ? place a bid
puts 'Place bid: ' + ProductManager.place_bid(user1, product1, 100).to_s
puts 'Place bid: ' + ProductManager.place_bid(user1, product1, 100).to_s
puts 'Place bid: ' + ProductManager.place_bid(user1, product1, 150).to_s

sleep(2)

puts 'Place bid: ' + ProductManager.place_bid(user1, product1, 180).to_s

puts 'Product id: ' + product1.id

get('/get') do
    slim(:home)
end

get('/profile/:username') do
    user = User.find_by_username(params[:username])
    slim(:profile, locals: { user: user })
end

get('/login') do
    slim(:login)
end

post('/login') do
    # TODO: add jwts (skip refresh tokens for now)

    user = User.find_by_username(params[:username])
    if user && Auth.authenticate(user, params[:password])
        session[:user_id] = user.id
        # TODO: replace user_id with token in session (json-web-token)

        redirect('/')
    else
        slim(:login)
    end
end

get('/logout') do
    session[:user_id] = nil
    redirect('/')
end

get('/register') do
    slim(:register)
end

post('/register') do
    # TODO: Password requirements
    # Todo: Email check
    # Todo: Username check
    # Todo: introduce type checks
    # Todo: check if account already exists

    user = User.new(params[:username], Auth.encrypt_password(params[:password]), nil, Time.now, params[:email])
    user.insert
    redirect('/')
end

# Product
get('/product/:product_id') do
    product = Product.find(params[:product_id])
    puts product.inspect
    slim(:product, locals: { product: product })
end

post('/product') do
    # TODO: introduce type checks

    user = User.find(session[:user_id])
    creation_date = Time.now
    expiration_date = creation_date + (5 * 24 * 60 * 60)
    product = Product.new(user.id, params[:title], params[:description], creation_date, expiration_date, false, nil,
                          nil)
    product.insert
    redirect('/')
end
