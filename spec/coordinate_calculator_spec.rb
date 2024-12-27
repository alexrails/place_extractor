# frozen_string_literal: true

require_relative '../app/coordinate_calculator'

RSpec.describe CoordinateCalculator do
  describe '.offset_coordinates' do
    let(:coordinates) { '37.7749,-122.4194' } # San Francisco coordinates (latitude, longitude)
    let(:offset) { 1000 } # Offset in meters

    it 'returns an array of offset coordinates' do
      result = CoordinateCalculator.offset_coordinates(coordinates, offset)

      expect(result).to be_an(Array)
      expect(result.size).to eq(4)

      result.each do |coordinate|
        expect(coordinate).to be_an(Array)
        expect(coordinate.size).to eq(2)
        expect(coordinate[0]).to be_a(Float) # Latitude
        expect(coordinate[1]).to be_a(Float) # Longitude
      end
    end

    it 'calculates the correct distance from the original point' do
      result = CoordinateCalculator.offset_coordinates(coordinates, offset)
      original_lat, original_lng = coordinates.split(',').map(&:to_f)

      diagonal_distance = Math.sqrt(2) * offset # Expected diagonal distance

      result.each do |new_lat, new_lng|
        # Calculate the approximate distance using the Haversine formula
        delta_lat = (new_lat - original_lat) * Math::PI / 180.0
        delta_lng = (new_lng - original_lng) * Math::PI / 180.0
        avg_lat_rad = (original_lat + new_lat) * Math::PI / 360.0

        x = delta_lng * Math.cos(avg_lat_rad)
        distance = CoordinateCalculator::EARTH_RADIUS * Math.sqrt(delta_lat**2 + x**2)

        expect(distance).to be_within(5).of(diagonal_distance) # Allow a small margin of error
      end
    end
  end
end
