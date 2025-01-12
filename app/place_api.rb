# frozen_string_literal: true

require 'httparty'
require 'resolv-replace'
require 'retryable'
require_relative '../config'
require_relative 'place_extractor'
require_relative 'interface'
require_relative 'logger'

class PlaceAPI
  BASE_URL = 'https://maps.googleapis.com/maps/api/place/nearbysearch/json'
  MAX_REQUESTS = 10
  RETRYABLE_ERRORS = [Net::OpenTimeout, HTTParty::Error, Resolv::ResolvError].freeze

  attr_reader :request_counter

  def initialize
    @request_counter = 0
  end

  def fetch_organizations(coordinates, radius, type)
    results = []
    next_page_token = nil

    loop do
      url = build_url(next_page_token, coordinates, radius, type)
      response = make_request(url)
      break unless response

      data = response.parsed_response
      break unless handle_response(data, results)

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
      location: coordinates,
      type: determine_type(radius, type)
    }
    query_params[:radius] = radius if radius > PlaceExtractor::MINIMAL_RADIUS
    query_params[:rankby] = :distance if radius <= PlaceExtractor::MINIMAL_RADIUS
    query_params[:pagetoken] = next_page_token if next_page_token

    "#{BASE_URL}?#{URI.encode_www_form(query_params)}"
  end

  def determine_type(radius, type)
    radius > PlaceExtractor::MINIMAL_RADIUS ? type : (type.empty? ? PlaceExtractor::DEFAULT_TYPE : type)
  end

  def make_request(url)
    Retryable.retryable(tries: 3, on: RETRYABLE_ERRORS, sleep: 1) do
      response = HTTParty.get(url, timeout: 10)
      @request_counter += 1

      return response if response.code == 200

      logger.error "Error: Received #{response.code} from Google Places API"
      nil
    end
  rescue => e
    logger.error("Error: #{e.message}. Returning current results")
    nil
  end

  def handle_response(data, results)
    case data['status']
    when 'ZERO_RESULTS'
      Interface.no_results
      false
    when 'OK'
      results.concat(data['results'])
      true
    else
      logger.error("Error: API Response Status - #{data['status']}")
      false
    end
  end

  def logger
    @logger ||= AppLogger.instance
  end
end
