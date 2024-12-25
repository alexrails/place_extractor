# frozen_string_literal: true

require 'httparty'
require_relative '../config'
require_relative 'place_extractor'
require_relative 'interface'

class PlaceAPI
  BASE_URL = 'https://maps.googleapis.com/maps/api/place/nearbysearch/json'
  attr_reader :request_counter

  def initialize
    @request_counter = 0
  end

  def fetch_organizations(coordinates, radius, type)
    next_page_token = nil
    results = []

    loop do
      url = build_url(next_page_token, coordinates, radius, type)
      response = HTTParty.get(url)
      @request_counter += 1

      if response.code != 200
        puts "Error: Received #{response.code} from Google Places API"
        break
      end

      data = response.parsed_response
      if data['status'] == 'ZERO_RESULTS'
        Interface.no_results
        break
      end

      if data['status'] != 'OK'
        puts "Error: API Response Status - #{data['status']}"
        break
      end

      results.concat(data['results'])
      next_page_token = data['next_page_token']

      break unless next_page_token
      sleep(2) # Required by Google API for subsequent requests
    end

    results
  end

  private

  def build_url(next_page_token, coordinates, radius, type)
    query_params = {
      key: Config::GOOGLE_PLACES_API_KEY,
      location: coordinates
    }

    if radius > PlaceExtractor::MINIMAL_RADIUS
      query_params[:radius] = radius
      query_params[:type] = type
    else
      query_params[:rankby] = :distance
      query_params[:type] = type.empty? ? PlaceExtractor::DEFAULT_TYPE : type
    end

    query_params[:pagetoken] = next_page_token if next_page_token
    "#{BASE_URL}?#{URI.encode_www_form(query_params)}"
  end
end
