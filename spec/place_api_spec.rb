# frozen_literal_string: true

require 'webmock/rspec'
require_relative '../app/place_api'

RSpec.describe PlaceAPI do
  let(:coordinates) { '37.7749,-122.4194' } # San Francisco coordinates
  let(:radius) { 1000 }
  let(:type) { 'restaurant' }
  let(:mock_api_key) { 'mock_api_key' }

  before do
    stub_const('Config::GOOGLE_PLACES_API_KEY', mock_api_key)
    stub_const('PlaceExtractor::MINIMAL_RADIUS', 500)
    stub_const('PlaceExtractor::DEFAULT_TYPE', 'default_type')
    allow(Interface).to receive(:no_results)
    allow_any_instance_of(PlaceAPI).to receive(:puts)
  end

  describe '#fetch_organizations' do
    let(:api_url) do
      "#{PlaceAPI::BASE_URL}?key=#{mock_api_key}&location=#{coordinates}&radius=#{radius}&type=#{type}"
    end

    context 'when the API returns a successful response' do
      before do
        stub_request(:get, api_url)
          .to_return(
            status: 200,
            body: {
              status: 'OK',
              results: [{ 'name' => 'Test Restaurant' }],
              next_page_token: nil
            }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'fetches the organizations successfully' do
        place_api = PlaceAPI.new
        results = place_api.fetch_organizations(coordinates, radius, type)

        expect(results).to be_an(Array)
        expect(results.size).to eq(1)
        expect(results.first['name']).to eq('Test Restaurant')
        expect(place_api.request_counter).to eq(1)
      end
    end

    context 'when the API returns a paginated response' do
      let(:paginated_url) { "#{PlaceAPI::BASE_URL}?key=#{mock_api_key}&location=#{coordinates}&pagetoken=next_page_token&radius=#{radius}&type=#{type}" }
    
      before do
        # Stub the initial request
        stub_request(:get, api_url)
          .to_return(
            status: 200,
            body: {
              status: 'OK',
              results: [{ 'name' => 'First Page Restaurant' }],
              next_page_token: 'next_page_token'
            }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
    
        # Stub the paginated request
        stub_request(:get, paginated_url)
          .to_return(
            status: 200,
            body: {
              status: 'OK',
              results: [{ 'name' => 'Second Page Restaurant' }],
              next_page_token: nil
            }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end
    
      it 'fetches all pages and aggregates results' do
        place_api = PlaceAPI.new
        results = place_api.fetch_organizations(coordinates, radius, type)
    
        expect(results.size).to eq(2)
        expect(results.map { |r| r['name'] }).to contain_exactly('First Page Restaurant', 'Second Page Restaurant')
        expect(place_api.request_counter).to eq(2)
      end
    end

    context 'when the API returns an error' do
      before do
        stub_request(:get, api_url)
          .to_return(status: 500, body: 'Internal Server Error')
      end

      it 'handles the error gracefully' do
        place_api = PlaceAPI.new
        results = place_api.fetch_organizations(coordinates, radius, type)

        expect(results).to be_empty
        expect(place_api.request_counter).to eq(1)
      end
    end

    context 'when there are no results' do
      before do
        stub_request(:get, api_url)
          .to_return(
            status: 200,
            body: {
              status: 'ZERO_RESULTS',
              results: []
            }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'returns an empty array' do
        place_api = PlaceAPI.new
        results = place_api.fetch_organizations(coordinates, radius, type)

        expect(results).to be_empty
        expect(place_api.request_counter).to eq(1)
      end
    end
  end
end
