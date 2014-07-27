require 'json'
require 'sinatra'
require 'simple_oauth'
require 'excon'
require 'gon-sinatra'
require_relative 'models'

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

  def create_report_data
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

get('/') do
  @tweets = []
  @report = Report.new({}, "")
  @report.words_count = [0]
  erb :home
end

get('/tweets_hashtag') do
  show_params
  if params[:q]
    search_word = params[:q]
    p "params[:q] is #{params[:q]} before calling prepend on search_word"
    hash_tag_encoded = search_word.prepend("%23")
    p "params[:q] is #{params[:q]} after calling prepend on search_word, but I didn't do anything with params[:q], oops?"
    p "search_word is #{search_word} after calling prepend"
    response = tweets_hashtag(hash_tag_encoded)
    @tweets = response["statuses"]
    @report = Report.new(@tweets, search_word)
    @report.calc_average_word_count
    @report.create_report_data
    gon.report = [@report.min_word_count, @report.max_word_count, @report.average_word_count]
    erb(:home)
  else
    @tweets = []
    redirect("/")
  end
end

get('/home.erb') do
  redirect("/")
end