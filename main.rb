# frozen_string_literal: true

require 'httparty'
require_relative 'config'
require 'csv'

class PlaceExtractor
  @@request_counter = 0

  BASE_URL = 'https://maps.googleapis.com/maps/api/place/nearbysearch/json'
  MINIMAL_RADIUS = 80
  OVER_QUERY_LIMIT = 2000
  DEFAULT_TYPE = "establishment"

  def initialize(coordinates, radius, query_limit = nil, type = nil)
    @lat = coordinates.first || raise(ArgumentError, 'Latitude must be provided')
    @lng = coordinates.last || raise(ArgumentError, 'Longitude must be provided')
    @radius = radius || raise(ArgumentError, 'Radius must be provided')
    @type = type
    @query_limit = query_limit || OVER_QUERY_LIMIT
    @all_results = []
  end

  def organizations
    scan_area(@lat, @lng, @radius, @radius)
    remove_duplicates
    write_to_csv
  end

  private

  def scan_area(center_lat, center_lng, radius, square_size)
    puts "****** Number of requests made: #{@@request_counter}"
    if @@request_counter < @query_limit
      results = fetch_organizations("#{center_lat},#{center_lng}", radius)
    else
      puts "---------------------------------------------"
      puts "STOP SCAN: Maximum number of requests reached"
      puts "---------------------------------------------"
      return nil
    end

    puts "Radius: #{radius}"
    if results.count >= 60
      puts "Warning: More than 60 results found in a single scan"
      offset = square_size / 2
      locations = offset_coordinates(center_lat, center_lng, offset)
      new_radius = offset * Math.sqrt(2)
      if radius > MINIMAL_RADIUS
        locations.each do |location|
          scan_area(location.first, location.last, new_radius, offset)
        end
      else
        puts "------------------------------------"
        puts "******* Minimal radius reached"
        results = locations.map do |location|
          fetch_organizations("#{location.first},#{location.last}", new_radius)
        end.flatten
        puts "------------------------------------"
      end
    end

    @all_results.concat(results)
  end

  def fetch_organizations(coordinates, radius)
    next_page_token = nil
    results = []

    loop do
      url = build_url(next_page_token, coordinates, radius)
      response = HTTParty.get(url)
      @@request_counter += 1
      if response.code != 200
        puts "Error: Received #{response.code} from Google Places API"
        break
      end

      data = response.parsed_response
      if data['status'] == 'ZERO_RESULTS'
        puts "No results found"
        break
      end

      if data['status'] != 'OK'
        puts "Error: API Response Status - #{data['status']}"
        break
      end

      results += data['results']
      next_page_token = data['next_page_token']

      break unless next_page_token
      sleep(2)
    end

    results
  end

  def build_url(next_page_token, coordinates, radius)
    query_params = {
      key: Config::GOOGLE_PLACES_API_KEY,
      location: coordinates
    }
    if radius > MINIMAL_RADIUS
      query_params[:radius] = radius
      query_params[:type] = @type
    else
      query_params[:rankby] = 'distance'
      query_params[:type] = @type || DEFAULT_TYPE
    end
    query_params[:pagetoken] = next_page_token if next_page_token

    "#{BASE_URL}?#{URI.encode_www_form(query_params)}"
  end

  def offset_coordinates(lat, lng, offset)
    earth_radius = 6378137.0
    lat_rad = lat * Math::PI / 180.0
    delta_lat = offset / earth_radius
    delta_lng = offset / (earth_radius * Math.cos(lat_rad))
    new_coordinates = []
    signs = [-1, 1]

    signs.each do |sign1|
      signs.each do |sign2|
        new_lat = lat + (sign1 * delta_lat * 180.0 / Math::PI)
        new_lng = lng + (sign2 * delta_lng * 180.0 / Math::PI)
        new_coordinates << [new_lat, new_lng]
      end
    end
    puts "********* New coordinates: #{new_coordinates} *********"
    new_coordinates
  end

  def remove_duplicates
    @all_results.uniq! { |place| place['place_id'] }
  end

  def write_to_csv
    prefix = @type.empty? ? 'all' : @type
    formatted_time = Time.now.strftime('%Y%m%d_%H:%M:%S')
    path = File.join(__dir__, 'files', "#{prefix}_organizations_#{formatted_time}.csv")

    Dir.mkdir(File.dirname(path)) unless File.exist?(File.dirname(path))
    CSV.open(path, 'wb') do |csv|
      csv << ['ID', 'Name', 'Address', 'Rating', 'Type', 'Coordinates', 'Website' ]

      @all_results.each do |place|
        csv << [place['place_id'], place['name'], place['vicinity'], place['rating'], place['types'].join(', '), place['geometry']['location'].values.join(', '), place['website']]
      end
    end
  end
end

# Main program
puts "Enter radius of the big circle (in meters):"
radius = gets.chomp.to_i

puts "Enter coordinates of the big circle's center (in degrees f.e: 41.623751152630476, 41.64793845178918):"
coordinates = gets.split(',').map(&:to_f)

puts "Enter maximum number of requests (optional, default - 2000):"
query_limit = gets.chomp.to_i.nonzero?

puts "Enter type of organizations (optional):"
type = gets.chomp

PlaceExtractor.new(coordinates, radius, query_limit, type).organizations
puts "Total requests made: #{PlaceFetcher.class_variable_get(:@@request_counter)}"
