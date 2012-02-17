class WordOfTheDay
  require 'nokogiri'
  require 'open-uri'
  require "sqlite3"
  
  CONTENT_URL = "http://wordsmith.org/awad/rss1.xml"
  SAMPLE_DATA = {:word => "ubiqitous", :definition => "Being or seeming to be everywhere at the same time."}
  def initialize
    @db = SQLite3::Database.new "word"
    create_table
  end
  
  def word_changed?
    new_word, new_definition = fetch_source
    # Update if new content
    if current_word != new_word
      # Add rollback if one of these fails
      set_definition new_definition
      set_word new_word
      return true
    end
    return false
  end
  
  def create_table
    rows = @db.execute ('CREATE TABLE IF NOT EXISTS key_value (key TEXT PRIMARY KEY, value TEXT)')
  end
  
  def current_word
    @db.get_first_value ("SELECT value FROM key_value WHERE key='word'")
  end
  
  def current_definition
    @db.get_first_value ("SELECT value FROM key_value WHERE key='definition'")
  end
  
  def set_word word
    result = @db.execute( %{
      REPLACE INTO key_value
      (key, value)
      VALUES ('%s', '%s')
    } % ["word", word] )
  end
  
  def set_definition definition
    result = @db.execute( %{
      REPLACE INTO key_value
      (key, value)
      VALUES ('%s', '%s')
    } % ["definition", definition] )
  end  
  
  def fetch_source      
    begin
      doc = Nokogiri.parse(open(CONTENT_URL))
    rescue OpenURI::HTTPError
      raise NetworkError, "Could not read to #{CONTENT_URL}"
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