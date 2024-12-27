# frozen_string_literal: true

require_relative '../app/csv_writer'

RSpec.describe CSVWriter do
  let(:results) do
    [
      {
        'place_id' => '123',
        'name' => 'Test Place',
        'vicinity' => '123 Test St',
        'rating' => 4.5,
        'types' => ['restaurant', 'bar'],
        'geometry' => { 'location' => { 'lat' => 40.7128, 'lng' => -74.0060 } },
        'business_status' => 'status',
        'user_ratings_total' => 13
      }
    ]
  end

  let(:type) { 'test' }
  let(:output_path) { File.expand_path('../results', __dir__) }
  let(:csv_file) { Dir.glob("#{output_path}/*.csv").first }

  before do
    FileUtils.rm_rf(output_path) # Clean up before running the test
  end

  after do
    FileUtils.rm_rf(output_path) # Clean up after running the test
  end

  it 'creates a CSV file with the correct content' do
    CSVWriter.write_to_csv(results, type)

    expect(File).to exist(csv_file)

    csv_content = CSV.read(csv_file)
    expect(csv_content[0]).to eq(['ID', 'Name', 'Address', 'Rating', 'Type', 'Coordinates', 'Business status', 'User ratings total'])
    expect(csv_content[1]).to eq(
      ['123', 'Test Place', '123 Test St', '4.5', 'restaurant, bar', '40.7128, -74.006', 'status', '13']
    )
  end
end
