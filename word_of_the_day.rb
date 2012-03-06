class WordOfTheDay
  require 'nokogiri'
  require 'open-uri'
  
  WORD_FILE = 'wotd.json'
  CONTENT_URL = "http://wordsmith.org/awad/rss1.xml"
  SAMPLE_DATA = {:word => "ubiqitous", :definition => "Being or seeming to be everywhere at the same time."}
  
  def initialize
    if !File.exists?(WORD_FILE)
      word, definition = fetch_source
      set_word word, definition
    end
    @wotd = JSON.parse (IO.read(WORD_FILE))
  end
  
  def word_changed?
    new_word, new_definition = fetch_source
    
    # Update if new content
    if @wotd['word'] != new_word
      set_word new_word, new_definition
      return true
    end
    return false
  end
  
  def set_word word, definition
   contents = {"definition" => definition, "word"=>word}.to_json
   File.open(WORD_FILE, 'w+') {|f| f.write(contents) }
   @wotd = JSON.parse (IO.read(WORD_FILE))
  end
  
  def current_word
    @wotd["word"]
  end
  
  def current_definition
    @wotd["definition"]
  end
  
  def fetch_source      
    begin
      doc = Nokogiri.parse(open(CONTENT_URL))
    rescue OpenURI::HTTPError
      raise NetworkError, "Could not read to #{CONTENT_URL}"
    rescue Timeout::Error
      raise NetworkError, "Connection to #{CONTENT_URL} timed out"
    end

    word = doc.xpath('//item/title').text
    raise PermanentError, "Parse error. Could not find the date item from #{CONTENT_URL}" if word.nil?
    raise PermanentError, "Parse error. Could not find the date item from #{CONTENT_URL}" if word == ""
    
    description = doc.xpath('//item/description').text
    raise PermanentError, "Parse error. Could not find the date item from #{CONTENT_URL}" if description.nil?
    raise PermanentError, "Parse error. Could not find the date item from #{CONTENT_URL}" if description == ""

    [word, description]
  end
end
class PermanentError < StandardError; end
class NetworkError < StandardError; end
class NotableError < StandardError; end