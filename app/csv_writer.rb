# frozen_string_literal: true

require 'csv'
require 'fileutils'

class CSVWriter
  def self.write_to_csv(results, type)
    prefix = type.empty? ? 'all' : type
    formatted_time = Time.now.strftime('%Y%m%d_%H:%M:%S')
    path = File.join(__dir__, '../results', "#{prefix}_organizations_#{formatted_time}.csv")

    FileUtils.mkdir_p(File.dirname(path))
    CSV.open(path, 'wb') do |csv|
      csv << ['ID', 'Name', 'Address', 'Rating', 'Type', 'Coordinates', 'Website']

      results.each do |place|
        csv << [
          place['place_id'],
          place['name'],
          place['vicinity'],
          place['rating'],
          place['types'].join(', '),
          place['geometry']['location'].values.join(', '),
          place['website']
        ]
      end
    end
  end
end
