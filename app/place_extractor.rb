# frozen_string_literal: true

require_relative 'logger'
require_relative 'interface'
require_relative 'place_api'
require_relative 'coordinate_calculator'
require_relative 'csv_writer'

class PlaceExtractor
  MINIMAL_RADIUS = 50
  OVER_QUERY_LIMIT = 2000
  MAX_PLACES_PER_REQUEST = 60
  DEFAULT_TYPE = 'establishment'

  def initialize
    Interface.welcome_message
    logger.info('Application started')
    @coordinates = Interface.coordinates
    @radius = Interface.radius
    @query_limit = Interface.query_limit || OVER_QUERY_LIMIT
    @type = Interface.type
    @scanned_area = 0
    @all_results = []
    @total_area = area_size(@radius)
    logger.info("Coordinates: #{@coordinates}, Radius: #{@radius}, Type: #{@type}, Query limit: #{@query_limit}")
  end

  def organizations
    scan_area(@coordinates, @radius, @radius)
    remove_duplicates
    write_to_csv
    running_complete
  end

  private

  def scan_area(coordinates, radius, square_size)
    return if @stop_scan
    return stop_scan if request_counter >= @query_limit 

    results = place_api.fetch_organizations(coordinates, radius, @type)

    logger.info("Scanning area: #{coordinates}, radius: #{radius}, results: #{results.count}, request_counter: #{request_counter}, scanned_percentage: #{scanned_percentage}")
    Interface.render_table(radius, request_counter, scanned_percentage, coordinates)

    if results.count >= MAX_PLACES_PER_REQUEST && radius > MINIMAL_RADIUS
      offset = square_size / 2
      new_radius = offset * Math.sqrt(2)
      locations = CoordinateCalculator.offset_coordinates(coordinates, offset)

      locations.each { |location| scan_area(location.join(','), new_radius, offset) }
    else
      @scanned_area += area_size(square_size)
      @all_results.concat(results)
    end
  end

  def place_api
    @place_api ||= PlaceAPI.new
  end

  def request_counter
    place_api.request_counter
  end

  def remove_duplicates
    @all_results.uniq! { |place| place['place_id'] }
  end

  def write_to_csv
    CSVWriter.write_to_csv(@all_results, @type)
  end

  # In fact, a square with a side of 2*r, circumscribed around a circle, will be scanned.
  def area_size(radius)
    4 * radius**2
  end

  def scanned_percentage
    return 0 if @scanned_area.zero?
    return 100 if @scanned_area >= @total_area

    (@scanned_area / @total_area.to_f * 100).round(2)
  end

  def logger
    AppLogger.instance
  end

  def stop_scan
    @stop_scan = true

    logger.info('Maximum number of requests reached. Scanning stopped')
    Interface.stop_scan
  end

  def running_complete
    logger.info('Scanning completed. Results saved to CSV')
    Interface.goodbye_message
  end
end
