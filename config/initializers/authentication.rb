# config/initializers/authentication.rb
ApplicationController.http_basic_auth_username = ENV['BASIC_AUTH_USERNAME'] || 'samvera'
ApplicationController.http_basic_auth_password = ENV['BASIC_AUTH_PASSWORD'] || 'hyku'
