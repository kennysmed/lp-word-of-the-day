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
        last_response.body.scan(WordOfTheDay::SAMPLE_DATA[:word].capitalize).length.should == 1
        last_response.body.scan(WordOfTheDay::SAMPLE_DATA[:definition]).length.should
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
    
    # Cronable
    describe 'cronable' do
      
      before (:each) do
        stub_request(:post, "http://staging.bergcoud.com/api/v1/publications/renders")
        File.stub!(:exists?).and_return(true)
        str = IO.read(File.join('spec_assets','word_of_the_day.json'))
        IO.stub!(:read).and_return(str)
        @wotd = WordOfTheDay.new
        WordOfTheDay.stub(:new).and_return(@wotd)
      end
      
      
      it '#should make a post to bergcloud if word_changed? == true' do
        stub_request(:post, "http://staging.bergcoud.com/api/v1/publications/renders")
        RestClient.should_receive(:post).exactly(1).times
        @wotd.stub(:word_changed?).and_return(true)
        cronable.should == true
      end
      
      it '#should do nothing if word_changed? returns false' do
        @wotd = WordOfTheDay.new()
        WordOfTheDay.stub(:new).and_return(@wotd)
        @wotd.stub(:word_changed?).and_return(false)
        RestClient.should_not_receive(:post)
        cronable.should == false
      end
    
    
      it '#should raise a NotableError if forecasts_changed? raises a permament error 3 times' do
        @wotd = WordOfTheDay.new()
        WordOfTheDay.stub(:new).and_return(@wotd)
        @wotd.should_receive(:word_changed?).exactly(3).times.and_raise(PermanentError)
        RestClient.should_not_receive(:post)
         lambda {
            cronable
          }.should raise_error(NotableError)
      end
      
    end
    
    
    # render_html
    describe '#render_html' do
       before (:each) do
          @wotd = Object.new
          WordOfTheDay.stub(:new).and_return(@wotd)
        end

      it '#should return html' do
        expected_result = "Procedure intended to establish the quality, performance, or reliability of something, esp. before it is taken into widespread use."
        word = "Test"
        
        @wotd.stub(:current_word).and_return(word)
        @wotd.stub(:current_definition).and_return(expected_result)
        
        html = render_html
        html.include?(expected_result).should == true
        html.include?(word).should == true
      end
    end
  end
  
  
  describe '#word_of_the_day' do

    describe '#word_changed?' do
      
      it '#should return true if the word/definition has changed, and update the word/definition' do
        s = IO.read('spec_assets/stub_data.xml')
        stub_request(:get, "http://wordsmith.org/awad/rss1.xml").
                 with(:headers => {'Accept'=>'*/*', 'User-Agent'=>'Ruby'}).
                 to_return(:status => 200, :body => s, :headers => {})
        
        old_definition = "sliced bread browned on both sides by exposure to radiant "
        old_world = "toast"
     
        
        @wotd = WordOfTheDay.new
        @wotd.set_word(old_world, old_definition)
              
        
        expected_result = "Procedure intended to establish the quality, performance, or reliability of something, esp. before it is taken into widespread use."
        word = "test"
        
        @wotd.stub(:fetch_source).and_return([word, expected_result])
        
        @wotd.word_changed?.should == true
        @wotd.current_word.should == word
        @wotd.current_definition.should == expected_result

      end
      
      it '#should return false if the forecasts have not changed' do
        old_definition = "sliced bread browned on both sides by exposure to radiant "
        old_world = "toast" 
        @wotd = WordOfTheDay.new 
        @wotd.set_word(old_world, old_definition)
              
        
        expected_result = "Procedure intended to establish the quality, performance, or reliability of something, esp. before it is taken into widespread use."
        word = "test"
        
        @wotd.stub(:fetch_source).and_return([word, expected_result])
        
        @wotd.word_changed?.should == true
        @wotd.current_word.should == word
        @wotd.current_definition.should == expected_result
        @wotd.word_changed?.should == false
        @wotd.current_word.should == word
        @wotd.current_definition.should == expected_result

      end
      
      
    end
  end
  
  describe '#fetch_source' do
    
    it "should update the word and definiton with whatever is returned from fetch_source" do

      s = IO.read('spec_assets/stub_data.xml')
      stub_request(:get, WordOfTheDay::CONTENT_URL).
      with(:headers => {'Accept'=>'*/*', 'User-Agent'=>'Ruby'}).
      to_return(:status => 200, :body => s, :headers => {})
      
      word, definition = wotd = WordOfTheDay.new.fetch_source
      word.should == "junoesque"
      definition.should == "Having a stately bearing and regal beauty; statuesque."
     
    end
    
    it "should throw a NetworkError if word of the day network errors" do
      stub_request(:get, WordOfTheDay::CONTENT_URL).
      with(:headers => {'Accept'=>'*/*', 'User-Agent'=>'Ruby'}).
      to_return(:status => 500, :body => "", :headers => {})

      lambda {
        WordOfTheDay.new.fetch_source
        }.should raise_error(NetworkError)
    end
    
    it "should throw a ParseError if the scraper can't find the word" do
      s = IO.read('spec_assets/stub_data_with_parse_error[word].xml')
      stub_request(:get, WordOfTheDay::CONTENT_URL).
      with(:headers => {'Accept'=>'*/*', 'User-Agent'=>'Ruby'}).
      to_return(:status => 200, :body => s, :headers => {})

      lambda {
        WordOfTheDay.new.fetch_source
      }.should raise_error(PermanentError)
    end
    it "should throw a NetworkError if word of the day network errors" do
      stub_request(:get, WordOfTheDay::CONTENT_URL).to_timeout

      lambda {
        WordOfTheDay.new.fetch_source
        }.should raise_error(NetworkError)  
    end
    
    it "should throw a ParseError if the scraper can't find the description" do
      s = IO.read('spec_assets/stub_data_with_parse_error[description].xml')
      stub_request(:get, WordOfTheDay::CONTENT_URL).
      with(:headers => {'Accept'=>'*/*', 'User-Agent'=>'Ruby'}).
      to_return(:status => 200, :body => s, :headers => {})

      lambda {
        WordOfTheDay.new.fetch_source
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
        json["content_type"].should == 'push'
      end
    end
    describe '#get config_options.json' do
      it 'should return json from config_options.json' do
        get '/config_options.json'
        last_response["Content-Type"].should == "application/json;charset=utf-8"
        json = JSON.parse(last_response.body)
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
