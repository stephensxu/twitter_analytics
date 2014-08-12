require 'sinatra'
require 'data_mapper'

if ENV['RACK_ENV'] != "production"
	DataMapper.setup(:default, "sqlite:reports.db")
end

if ENV['RACK_ENV'] == "production"
  DataMapper.setup(:default, ENV["DATABASE_URL"])
end

class Report_data
  include DataMapper::Resource
  property :id, Serial
  property :tag_name, String
  property :created_at, DateTime
  property :average_word_count, Float
  property :min_word_count, Integer
  property :max_word_count, Integer
  property :total_tweets, Integer
end

DataMapper.finalize
DataMapper.auto_upgrade!
