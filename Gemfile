source "https://rubygems.org"
ruby '2.1.2'

gem "sinatra"
gem "simple_oauth"
gem "excon"
gem "gon-sinatra"
gem 'data_mapper'

group :development do
  gem 'sqlite3'
  gem 'dm-sqlite-adapter'
  gem 'dotenv'
  gem 'rerun'
end

group :production do
  gem 'dm-postgres-adapter'
  gem 'pg'
end
