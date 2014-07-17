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

def words_count(string)
  string.split(" ").count
end

def average_word_count(array)
  total_words = 0
  array.each do |string|
    total_words += words_count(string)
  end
  total_words / array.count
end

def tweets_hashtag(hash_tag)
  authorization_header = SimpleOAuth::Header.new("get",
                                                 "https://api.twitter.com/1.1/search/tweets.json",
                                                 { :q => hash_tag },
                                                 { :consumer_key => ENV['TWITTER_API_KEY'],
                                                   :consumer_secret => ENV['TWITTER_API_SECRET'] })

  response = Excon.send("get", "https://api.twitter.com/1.1/search/tweets.json", {
    :query => { :q => hash_tag },
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

get('/') do
  @tweets = []
  @min_count = 0
  @max_count = 0
  @average_word_count = 0
  erb :home
end

get('/tweets_hashtag') do
  show_params
  if params[:q]
    hash_tag = params[:q].prepend("%23")
    response = tweets_hashtag(hash_tag)
    @tweets = response["statuses"]
    tweets_array = []
    @tweets.each { |tweet| tweets_array << tweet["text"] }
    @average_word_count = average_word_count(tweets_array)
    words_count = tweets_array.map { |string| words_count(string) }
    @min_count = words_count.min
    @max_count = words_count.max
    @report = [@min_count, @max_count, @average_word_count]
    gon.report = @report
    p @report
    erb(:home)
  else
    @tweets = []
    redirect("/")
  end
end

get('/home.erb') do
  redirect("/")
end