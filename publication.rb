require 'sinatra'
require 'json'
require 'rest-client'
require './word_of_the_day'
require 'date'

post '/validate_config/' do
  content_type :json
  response = {}
  response[:errors] = []
  response[:valid] = true
  response.to_json
end

get '/sample/' do
  require './word_of_the_day'
  @word = WordOfTheDay::SAMPLE_DATA[0]
  @definition = WordOfTheDay::SAMPLE_DATA[1]
  erb :word_of_the_day
end

get '/edition/' do
  success = false
  tries = 0
  while !success && tries < 3
    tries +=1
    begin
      @word, @definition = WordOfTheDay.fetch_source
      success = true
    rescue Exception => e
      
      if tries == 3
        etag Digest::MD5.hexdigest(Time.now.getutc.to_s)
        return 502
      end 
    end
  end
  etag Digest::MD5.hexdigest(@word+@definition)
  erb :word_of_the_day
end
