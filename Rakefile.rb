desc "This task is called by the Heroku scheduler add-on"
task :scraper_check do
  require './publication.rb'
  cronable
end