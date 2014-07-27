require 'sinatra'
require 'data_mapper'
require 'bcrypt'

if ENV['RACK_ENV'] != "production"
	DataMapper.setup(:default, "sqlite:reports.db")
end

if ENV['RACK_ENV'] == "production"
  DataMapper.setup(:default, ENV["DATABASE_URL"])
end

class Report
  include DataMapper::Resource
  attr_reader :tweets_hash, :tweets_text_array, :run_at
  attr_accessor :words_count
  property :id,       Serial
  property :created_at, DateTime
  def initialize(tweets)
    @run_at = Time.now
    @tweets_hash = tweets
    @tweets_text_array = []
    @tweets_hash.each { |tweet| @tweets_text_array << tweet["text"] }
    @words_count = @tweets_text_array.map { |string| string.split(" ").count }
  end

  def average_word_count
    total_words = 0
    @tweets_text_array.each do |string|
      total_words += string.split(" ").count
    end

    if @tweets_text_array.count == 0
      0
    else
      total_words.to_f / @tweets_text_array.count.to_f
    end
  end

  def min_word_count
    @words_count.min
  end

  def max_word_count
    @words_count.max
  end

  def total_tweets
    @tweets_text_array.count
  end
end
