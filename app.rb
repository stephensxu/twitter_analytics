require 'json'
require 'sinatra'
require 'simple_oauth'
require 'excon'
require 'gon-sinatra'
require 'uri'
require 'date'
require_relative 'models'

Sinatra::register Gon::Sinatra

if ENV['RACK_ENV'] != "production"
  require 'dotenv'
  Dotenv.load ".env"
end

def show_params
  p "params are #{params}"
end

##### twitter api 

def tweets_hashtag(hashtag)
  hashtag[0] == "#" ? search_term = hashtag : search_term = ("#" + "#{hashtag}")
  p "search term is #{search_term}"
  twitter_api_search(search_term, :count => 100)
end

def twitter_api_url(endpoint, version = '1.1')
  "https://api.twitter.com/#{version}#{endpoint}"
end

def twitter_api_search(search_term, params = {})
  twitter_api_get_request("/search/tweets.json", params.merge(:q => URI.encode("#{search_term}")))
end

def twitter_api_get_request(endpoint, params, consumer_key = ENV['TWITTER_API_KEY'], consumer_secret = ENV['TWITTER_API_SECRET'])
  twitter_api_request("get", endpoint, params, consumer_key, consumer_secret)
end

def twitter_api_request(method, endpoint, params, consumer_key = ENV['TWITTER_API_KEY'], consumer_secret = ENV['TWITTER_API_SECRET'])
  api_url = twitter_api_url(endpoint)

  authorization_header = SimpleOAuth::Header.new(method,
                                                 api_url,
                                                 params,
                                                 { :consumer_key => consumer_key,
                                                   :consumer_secret => consumer_secret})


  response = Excon.send(method, api_url, {
    :query => params,
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

def query_twitter_api(search_word)
  response = tweets_hashtag(search_word)
  @tweets = response["statuses"]
  @report = Report.new(@tweets, search_word)
  @report.calc_average_word_count
  @report.save_report_data
end

##### Report class

class Report
  attr_reader :tweets_hash, :tweets_text_array, :run_at, :average_word_count
  attr_accessor :words_count
  def initialize(tweets, tag)
    @tag = tag
    @run_at = Time.now
    @tweets_hash = tweets
    @tweets_text_array = []
    @tweets_hash.each { |tweet| @tweets_text_array << tweet["text"] }
    @words_count = @tweets_text_array.map { |string| string.split(" ").count }
    @average_word_count = 0
  end

  def calc_average_word_count
    total_words = 0
    @tweets_text_array.each do |string|
      total_words += string.split(" ").count
    end

    if @tweets_text_array.count == 0
      @average_word_count = 0
    else
      @average_word_count = total_words.to_f / @tweets_text_array.count.to_f
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

  def save_report_data
    report_data_attributes = {
      "tag_name" => @tag,
      "created_at" => @run_at,
      "average_word_count" => @average_word_count,
      "min_word_count" => @words_count.min,
      "max_word_count" => @words_count.max,
      "total_tweets" => @tweets_text_array.count
    }
  Report_data.create(report_data_attributes)
  end
end

##### routes

get('/') do
  @tweets = []
  @report = Report.new({}, "")
  @report.words_count = [0]
  erb :home
end

get('/tweets_hashtag') do
  show_params
  @search_word = params[:q]
  @saved_report = Report_data.last(:tag_name => @search_word)
  if @search_word == ""
    redirect("/")
  elsif !@saved_report
    query_twitter_api(@search_word)
    gon.report = [@report.min_word_count, @report.max_word_count, @report.average_word_count]
    erb(:home)
  elsif @saved_report && (DateTime.now - @saved_report.created_at) * 24.0 <= 1.0
    gon.report = [@saved_report.min_word_count, @saved_report.max_word_count, @saved_report.average_word_count]
    erb(:cached_report)
  elsif @saved_report && (DateTime.now - @saved_report.created_at) * 24.0 > 1.0
    query_twitter_api(@search_word)
    gon.report = [@report.min_word_count, @report.max_word_count, @report.average_word_count]
    erb(:home)
  end
end

get('/home') do
  redirect("/")
end
