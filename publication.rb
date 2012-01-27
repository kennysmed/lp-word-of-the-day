require 'sinatra'
require 'json'
require 'rest-client'

get '/admin' do
  erb :admin
end

post '/push' do
  RestClient.post("http://localhost:3000/api/v1/publications/renders", :config => params["config"], :html => render_html(params['config']), :developer_key => '5f772202c244e5ecc5ac7b7554da1096', :endpoint => 'http://localhost:9292/')
  "Published"
end

def render_html(config)
  "<html><body><h1>#{config['word']}</h1><h2>#{config['definition']}</h2></body></html>"
end

post '/validate_config' do
  content_type :json
  response = {}
  response[:errors] = []
  response[:valid] = true
  response.to_json
end