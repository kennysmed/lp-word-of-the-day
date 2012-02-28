require 'sinatra'
require 'json'
require 'rest-client'

post '/validate_config/' do
  content_type :json
  response = {}
  response[:errors] = []
  response[:valid] = true
  response.to_json
end

get '/sample/' do
  require './word_of_the_day'
  @word = WordOfTheDay::SAMPLE_DATA[:word]
  @definition = WordOfTheDay::SAMPLE_DATA[:definition]
  erb :word_of_the_day
end

#TODO::AB POKE ME WITH YOUR CRON JOB
#TODO::AB REMOVE REFS TO LOCAL HOST
def cronable
  require './word_of_the_day'
  @wotd = WordOfTheDay.new
  
  
  success = false
  tries = 0
   
  while !success && tries < 3
    tries +=1
    begin
      result = @wotd.word_changed?
      if result
        RestClient.post("http://staging.bergcloud.com/api/v1/publications/renders", :config => {}, :html => render_html, :developer_key => 'a94d7051b1b93e39451e653179cac8ae', :endpoint => 'http://empty-stream-2306.herokuapp.com/')
      end
      success = true
    rescue PermanentError => e
      # Parse problem. Not going to go away. Do someting #TODO AB Make this error notify by email or something
      raise NotableError, 'caught a parse error 3 times. Last error message: '+ e.message if tries == 3
    rescue NetworkError
      # Network error. Do nothing.
    end
  end
  return result
end

def render_html
  bind_me = BindMe.new(@wotd.current_word, @wotd.current_definition)
  rhtml = ERB.new(File.read('views/word_of_the_day.erb'))
  rhtml.result(bind_me.get_binding)
end

class BindMe
  def initialize(word, definition)
    @word=word
    @definition=definition
  end
  def get_binding
    return binding()
  end
end