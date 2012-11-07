require './publication'
require './word_of_the_day'
require 'rspec'
require 'rack/test'
require 'json'
require 'webmock/rspec'
set :environment, :test

describe 'Word Of The Day Publication' do
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end
  
  describe '#publication' do
    
    # Get Sample
    describe '#Get sample' do
      it '#should return a sample for a GET to sample. The sample should contain word of the day test data' do
        get '/sample/'
        last_response.should be_ok
        last_response.body.scan(WordOfTheDay::SAMPLE_DATA[0].capitalize).length.should == 1
        last_response.body.scan(WordOfTheDay::SAMPLE_DATA[1]).length.should
      end
    end
      
    describe '#validate_config' do
      # Post validate_config
      it 'should return valid for all config' do
        post '/validate_config/', :config => {"any_config" => "sign"}.to_json
        resp = JSON.parse(last_response.body)
        resp["valid"].should == true
      end
      
      # Post validate_config
      it 'not fail for no config. It should fail with an error message' do
        post '/validate_config/', {}.to_json
        resp = JSON.parse(last_response.body)
        resp["valid"].should == true

      end
    end
    
    describe 'edition' do
      
      it 'should return html for a pull' do
        word = "test"
        definition = "something to do with cricket."
        WordOfTheDay.stub!(:fetch_source).and_return([word, definition])
        get '/edition/'
        last_response.should be_ok
        # should include location/forecast/etc
        last_response.body.scan(word.capitalize).length.should == 1
        last_response.body.scan(definition).length.should == 1
      end

      # It should throw a 502 after three erroring (with network) calls to fetch_data
      it 'should retry three times before returning a 502 if there is an upstream error' do
        WordOfTheDay.stub!(:fetch_source).and_raise(NetworkError)
        WordOfTheDay.should_receive(:fetch_source).exactly(3).times
        get '/edition/'
        last_response.status.should == 502
      end

      it 'should set an etag that changes every hour' do
        WordOfTheDay.stub!(:fetch_source).and_return(WordOfTheDay::SAMPLE_DATA)
     
        get '/edition/'
        etag_one = last_response.original_headers["ETag"]
        
        WordOfTheDay.stub!(:fetch_source).and_return(["test", "something to do with cricket."])
        get '/edition/'
        etag_two = last_response.original_headers["ETag"]

        get '/edition/'
        etag_three = last_response.original_headers["ETag"]


        etag_one.should_not == etag_two
        etag_two.should == etag_three
      end
    end
  end
  
  describe '#fetch_source' do
    
    it "should update the word and definiton with whatever is returned from fetch_source" do

      s = IO.read('spec_assets/stub_data.xml')
      stub_request(:get, WordOfTheDay::CONTENT_URL).
      with(:headers => {'Accept'=>'*/*', 'User-Agent'=>'Ruby'}).
      to_return(:status => 200, :body => s, :headers => {})
      
      word, definition =  WordOfTheDay::fetch_source
      word.should == "junoesque"
      definition.should == "Having a stately bearing and regal beauty; statuesque."
     
    end
    
    it "should throw a NetworkError if word of the day network errors" do
      stub_request(:get, WordOfTheDay::CONTENT_URL).
      with(:headers => {'Accept'=>'*/*', 'User-Agent'=>'Ruby'}).
      to_return(:status => 500, :body => "", :headers => {})

      lambda {
        WordOfTheDay::fetch_source
        }.should raise_error(NetworkError)
    end
    
    it "should throw a ParseError if the scraper can't find the word" do
      s = IO.read('spec_assets/stub_data_with_parse_error[word].xml')
      stub_request(:get, WordOfTheDay::CONTENT_URL).
      with(:headers => {'Accept'=>'*/*', 'User-Agent'=>'Ruby'}).
      to_return(:status => 200, :body => s, :headers => {})

      lambda {
        WordOfTheDay::fetch_source
      }.should raise_error(PermanentError)
    end
    it "should throw a NetworkError if word of the day network errors" do
      stub_request(:get, WordOfTheDay::CONTENT_URL).to_timeout

      lambda {
        WordOfTheDay::fetch_source
        }.should raise_error(NetworkError)  
    end
    
    it "should throw a ParseError if the scraper can't find the description" do
      s = IO.read('spec_assets/stub_data_with_parse_error[description].xml')
      stub_request(:get, WordOfTheDay::CONTENT_URL).
      with(:headers => {'Accept'=>'*/*', 'User-Agent'=>'Ruby'}).
      to_return(:status => 200, :body => s, :headers => {})

      lambda {
        WordOfTheDay::fetch_source
      }.should raise_error(PermanentError)
    end
  end
  
 
  
  #
  # Generic statements about push publication (asset checking)
  #
  describe '#assets' do
    describe '#get meta.json' do
      it 'should return json for meta.json' do
        get '/meta.json'
        last_response["Content-Type"].should == "application/json;charset=utf-8"
        json = JSON.parse(last_response.body)
        json["name"].should_not == nil
        json["description"].should_not == nil
      end
    end

    describe '#get icon' do
      it 'should return a png for /icon' do
        get '/icon.png'
        last_response['Content-Type'].should == 'image/png'
      end
    end
  end
end
