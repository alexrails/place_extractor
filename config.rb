require 'dotenv'
Dotenv.load

module Config
  GOOGLE_PLACES_API_KEY = ENV['GOOGLE_PLACES_API_KEY']
end
