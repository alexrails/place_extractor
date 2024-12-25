# frozen_string_literal: true

class CoordinateCalculator
  EARTH_RADIUS = 6378137.0

  def self.offset_coordinates(coordinates, offset)
    lat, lng = coordinates.split(',').map(&:to_f)
    lat_rad = lat * Math::PI / 180.0
    delta_lat = offset / EARTH_RADIUS
    delta_lng = offset / (EARTH_RADIUS * Math.cos(lat_rad))
    new_coordinates = []

    [-1, 1].each do |sign1|
      [-1, 1].each do |sign2|
        new_lat = lat + (sign1 * delta_lat * 180.0 / Math::PI)
        new_lng = lng + (sign2 * delta_lng * 180.0 / Math::PI)
        new_coordinates << [new_lat, new_lng]
      end
    end

    new_coordinates
  end
end
