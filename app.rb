require 'json'
require 'sinatra'
require 'simple_oauth'
require 'excon'
require 'gon-sinatra'

Sinatra::register Gon::Sinatra

if ENV['RACK_ENV'] != "production"
  require 'dotenv'
  Dotenv.load ".env"
end

def show_params
  p "params are #{params}"
end

def tweets_hashtag(hash_tag)
  authorization_header = SimpleOAuth::Header.new("get",
                                                 "https://api.twitter.com/1.1/search/tweets.json",
                                                 { :q => hash_tag, :count => 100 },
                                                 { :consumer_key => ENV['TWITTER_API_KEY'],
                                                   :consumer_secret => ENV['TWITTER_API_SECRET'] })

  response = Excon.send("get", "https://api.twitter.com/1.1/search/tweets.json", {
    :query => { :q => hash_tag, :count => 100 },
    :headers => { "Authorization" => authorization_header.to_s }
  })

  response = JSON.parse(response.body)
  if response.respond_to?(:has_key?) && response.has_key?("errors")
    messages = []
    response["errors"].each do |error|
      messages.push(error["message"])
    end
    raise "Oops, errors! #{messages.join("\n")}"
  else
    return response
  end
end

class Report
  attr_accessor :tweets_hash, :tweets_text_array, :words_count
  def initialize(tweets)
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
      total_words / @tweets_text_array.count
    end
  end

  def date
    Time.now
  end

  def min_count
    @words_count.min
  end

  def max_count
    @words_count.max
  end

  def total_tweets
    @tweets_text_array.count
  end
end

get('/') do
  @tweets = []
  @report = Report.new({})
  @report.words_count = [0]
  erb :home
end

get('/tweets_hashtag') do
  show_params
  if params[:q]
    hash_tag = params[:q].prepend("%23")
    response = tweets_hashtag(hash_tag)
    @tweets = response["statuses"]
    @report = Report.new(@tweets)
    gon.report = [@report.min_count, @report.max_count, @report.average_word_count]
    erb(:home)
  else
    @tweets = []
    redirect("/")
  end
end

get('/home.erb') do
  redirect("/")
end