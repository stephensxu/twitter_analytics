require 'json'
require 'sinatra'
require 'simple_oauth'
require 'excon'
require 'open-uri'
require 'nokogiri'

if ENV['RACK_ENV'] != "production"
  require 'dotenv'
  Dotenv.load ".env"
end

def show_params
  p "params are #{params}"
end

def tweets(screen_name)
  authorization_header = SimpleOAuth::Header.new("get",
                                                 "https://api.twitter.com/1.1/statuses/user_timeline.json",
                                                 { :screen_name => screen_name },
                                                 { :consumer_key => ENV['TWITTER_API_KEY'],
                                                   :consumer_secret => ENV['TWITTER_API_SECRET'] })

  response = Excon.send("get", "https://api.twitter.com/1.1/statuses/user_timeline.json", {
    :query => { :screen_name => screen_name },
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
  erb :home
end

get('/tweets') do
  show_params
  if params[:screen_name]
    @tweets = tweets(params[:screen_name])
    puts @tweets.class
    erb(:home)
  else
    @tweets = []
    redirect("/")
  end
end

get('/tweets_hashtag') do
  show_params
  if params[:q]
    hash_tag = params[:q].prepend("%23")
    response = tweets_hashtag(hash_tag)
    @tweets = response["statuses"]
    erb(:home)
  else
    @tweets = []
    redirect("/")
  end
end

get('/home.erb') do
  redirect("/")
end