require 'sinatra'
require 'json'
require 'rest-client'

get '/admin' do
  erb :admin
end

get '/test' do
  require './word_of_the_day'
  @wotd = WordOfTheDay.new
  puts render_html
end

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
def check_words
  require './word_of_the_day'
  @wotd = WordOfTheDay.new
  if @wotd.word_changed?
    RestClient.post("http://localhost:3000/api/v1/publications/renders", :config => params["config"], :html => render_html, :developer_key => '5f772202c244e5ecc5ac7b7554da1096', :endpoint => 'http://localhost:9292/')
  end
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