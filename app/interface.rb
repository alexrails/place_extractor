# frozen_string_literal: true

require_relative 'validator'

class Interface
  def self.render_table(radius, requests_number, scanned_percentage, coordinates)
    system('clear') || system('cls')
    puts "START RADIUS: #{@start_radius} m"
    puts "QUERY LIMIT: #{@query_limit}"
    puts "TYPE: #{@type}"
    puts "CURRENT COORDINATES: #{coordinates}"
    puts "-------------------------------------------"
    puts "|  Radius, m |Requests number| Percentage |"
    puts "-----------------------------------------"
    printf("| %-10.2f | %-13d | %-10.2f |\n", radius, requests_number, scanned_percentage)
    puts "-------------------------------------------"
  end

  def self.welcome_message
    version ||= File.read(File.join(__dir__, '../.app_version')).strip

    puts "==============================================================================================="
    puts "Welcome to the Place Extractor(#{version})!"
    puts "This program will extract all organizations in a given area."
    puts "Be sure to have your Google API key ready assigned to the GOOGLE_PLACES_API_KEY environment variable."
    puts "Be aware that this program will make a lot of requests to the Google Places API."
    puts "==============================================================================================="
  end

  def self.coordinates
    handle_errors do
      puts "For multiple areas, please enter the coordinates of the area you want to scan (latitude,longitude) separated by ;"
      puts "Example: 40.7128,-74.0060;41.8781,-87.6298"
      puts "Please enter the coordinates of the area you want to scan (latitude,longitude):"
      @start_coordinates = gets.chomp.split(';')

      @start_coordinates.each do |coordinates|
        Validator.validate_coordinates(coordinates)
      end

      @start_coordinates
    end
  end

  def self.radius
    handle_errors do
      puts "Please enter the radius in meters:"
      @start_radius = gets.chomp.to_i
      Validator.validate_radius(@start_radius)
      @start_radius
    end
  end

  def self.type
    handle_errors do
      puts "Please enter the type of organization you are looking for(optional):"
      @type = gets.chomp
      Validator.validate_type(@type)
      @type
    end
  end

  def self.query_limit
    handle_errors do
      puts "Please enter the maximum number of queries you want to make(optional, default = 2000):"
      @query_limit = gets.chomp.to_i.nonzero?
      Validator.validate_query_limit(@query_limit)
      @query_limit
    end
  end

  def self.scanned_percentage(percentage)
    puts "Scanned #{percentage}% of the area"
  end

  def self.requests_number(number)
    puts "Number of requests made: #{number}"
  end

  def self.stop_scan
    puts "---------------------------------------------"
    puts "STOP SCAN: Maximum number of requests reached"
    puts "---------------------------------------------"
  end

  def self.current_radius(radius)
    puts "Radius: #{radius}"
  end

  def self.no_results
    puts "No results found"
  end

  def self.goodbye_message
    puts "==========================================="
    puts " Thank you for using the Place Extractor!"
    puts "==========================================="
  end

  def self.handle_errors
    raise ArgumentError, "no_block_given" unless block_given?

    yield
  rescue ArgumentError => e
    puts "Error: #{e.message}"
    logger.error(e.message)
    retry
  end

  private

  def self.logger
    AppLogger.instance
  end
end
