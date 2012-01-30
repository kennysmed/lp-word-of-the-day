class WordOfTheDay
  require 'nokogiri'
  require 'open-uri'
  require "sqlite3"
  
  CONTENT_URL = "http://wordsmith.org/awad/rss1.xml"
  
  def initialize
    @db = SQLite3::Database.new "word"
    make_table
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
  
  def make_table
    rows = @db.execute ('CREATE TABLE IF NOT EXISTS key_value (key varchar(10) PRIMARY KEY, value varchar(1000))')
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
    
  # TODO::AB Currently not monitoring how many errors we are getting. Probably want to add a threshold for when the fails count is about X for network and X for parse.
  def update_self
    # Check word of the day website
    begin
      new_word, new_description = fetch_source
    catch NetworkError
      return false
    end
    # Is the word different to current?
    if new_word != current_word
    # Update
      current_word = new_word
      current_description = new_description
      return true
    else
      return false
    end
  end
  
  def fetch_source      
    begin
      doc = Nokogiri.parse(open(CONTENT_URL))
    rescue OpenURI::HTTPError
      raise NetworkError "Could not read to #{CONTENT_URL}"
    end

    word = doc.xpath('//item/title').text
    raise ParseError "Parse error. Could not find the date item from #{CONTENT_URL}" if word.nil?
    raise ParseError "Parse error. Could not find the date item from #{CONTENT_URL}" if word == ""
    
    description = doc.xpath('//item/description').text
    raise ParseError "Parse error. Could not find the date item from #{CONTENT_URL}" if description.nil?
    raise ParseError "Parse error. Could not find the date item from #{CONTENT_URL}" if description == ""

    [word, description]
  end
  
  class PermenantError < StandardError; end
  class NetworkError < StandardError; end


end