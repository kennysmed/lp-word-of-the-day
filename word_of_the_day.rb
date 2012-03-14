class WordOfTheDay
  require 'nokogiri'
  require 'open-uri'
  
  CONTENT_URL = "http://wordsmith.org/awad/rss1.xml"
  SAMPLE_DATA = {:word => "ubiquitous", :definition => "Being or seeming to be everywhere at the same time."}

  def self.fetch_source      
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