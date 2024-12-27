# frozen_string_literal: true

require_relative '../app/place_extractor'

RSpec.describe PlaceExtractor do
  let(:coordinates) { '37.7749,-122.4194' } # Mock coordinates
  let(:radius) { 1000 }
  let(:type) { 'restaurant' }
  let(:query_limit) { 5 }
  let(:place_api) { instance_double('PlaceAPI') }
  let(:logger) { instance_double('AppLogger') }

  before do
    allow(Interface).to receive(:welcome_message)
    allow(Interface).to receive(:coordinates).and_return(coordinates)
    allow(Interface).to receive(:radius).and_return(radius)
    allow(Interface).to receive(:query_limit).and_return(query_limit)
    allow(Interface).to receive(:type).and_return(type)
    allow(Interface).to receive(:render_table)
    allow(Interface).to receive(:stop_scan)
    allow(Interface).to receive(:goodbye_message)
  
    # Mock the AppLogger instance
    logger = instance_double(Logger)
    allow(logger).to receive(:info) # Stub the `info` method
    allow(AppLogger).to receive(:instance).and_return(logger) # Return the mocked logger
  
    allow(PlaceAPI).to receive(:new).and_return(place_api)
    allow(CSVWriter).to receive(:write_to_csv)
    allow(CoordinateCalculator).to receive(:offset_coordinates).and_return([[37.7750, -122.4195], [37.7748, -122.4193], [37.7748, -122.4195], [37.7750, -122.4193]])
  end

  describe '#initialize' do
    it 'initializes with the correct values' do
      extractor = PlaceExtractor.new

      expect(extractor.instance_variable_get(:@coordinates)).to eq(coordinates)
      expect(extractor.instance_variable_get(:@radius)).to eq(radius)
      expect(extractor.instance_variable_get(:@query_limit)).to eq(query_limit)
      expect(extractor.instance_variable_get(:@type)).to eq(type)
    end
  end

  describe '#scan_area' do
    let(:first_results) { Array.new(PlaceExtractor::MAX_PLACES_PER_REQUEST) { { 'place_id' => '1' } } }
    let(:second_results) { [{ 'place_id' => '2' }] }

    before do
      # Stub fetch_organizations to return results in two stages: first triggers recursion, second stops it.
      allow(place_api).to receive(:fetch_organizations).and_return(first_results, second_results)
      allow(place_api).to receive(:request_counter).and_return(1, 2)
    end

    it 'recursively scans areas with smaller offsets' do
      extractor = PlaceExtractor.new

      expect(place_api).to receive(:fetch_organizations).exactly(5).times
      extractor.send(:scan_area, coordinates, radius, radius)
    end

    it 'stops scanning if the request limit is reached' do
      allow(place_api).to receive(:request_counter).and_return(query_limit)
      extractor = PlaceExtractor.new

      extractor.send(:scan_area, coordinates, radius, radius)
      expect(Interface).to have_received(:stop_scan).once
    end
  end

  describe '#remove_duplicates' do
    it 'removes duplicate results based on place_id' do
      extractor = PlaceExtractor.new
      results = [
        { 'place_id' => '1', 'name' => 'Place 1' },
        { 'place_id' => '1', 'name' => 'Duplicate Place 1' },
        { 'place_id' => '2', 'name' => 'Place 2' }
      ]
      extractor.instance_variable_set(:@all_results, results)

      extractor.send(:remove_duplicates)
      expect(extractor.instance_variable_get(:@all_results).size).to eq(2)
    end
  end

  describe '#write_to_csv' do
    it 'writes results to a CSV file' do
      extractor = PlaceExtractor.new
      results = [{ 'place_id' => '1', 'name' => 'Place 1' }]
      extractor.instance_variable_set(:@all_results, results)

      extractor.send(:write_to_csv)
      expect(CSVWriter).to have_received(:write_to_csv).with(results, type)
    end
  end

  describe '#organizations' do
    it 'executes the full flow' do
      allow(place_api).to receive(:fetch_organizations).and_return([])
      allow(place_api).to receive(:request_counter).and_return(1)

      extractor = PlaceExtractor.new

      extractor.organizations

      expect(place_api).to have_received(:fetch_organizations)
      expect(CSVWriter).to have_received(:write_to_csv)
      expect(Interface).to have_received(:goodbye_message)
    end
  end
end
