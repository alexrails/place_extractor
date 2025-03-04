# Place Extractor

Place Extractor is a Ruby application that extracts organizations from a specific geographic area using the Google Places API.
It allows users to specify coordinates, radius, organization type, and query limits. The results are saved to a CSV file.

## Prerequisites

- **Ruby**: Ensure you have Ruby installed (version 3.4.0 or later).
- **Google API Key**: A valid API key is required for the Google Places API. Set the key as an environment variable:

  ```bash
    export GOOGLE_PLACES_API_KEY=your_api_key
  ```

## Installation

  1. Clone the repository:
    ```bash
      git clone https://github.com/alexrails/place_extractor.git
      cd place_extractor
    ```

  2. Install dependencies:
    ```bash
      bundle install
    ```

## Usage

  1. Run the application:
    ```bash
      ruby main.rb
    ```

  2. Follow the on-screen prompts to:
      •	Enter coordinates (latitude,longitude).
      •	Enter the search radius in meters.
      •	Specify the type of organization (optional).
      •	Define the maximum number of queries (optional, default is 2000).

  3. The application will extract data and save it to a CSV file in the results/ directory.

## Logging

  •	All main events and errors are logged in application.log.
