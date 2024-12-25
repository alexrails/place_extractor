# frozen_literal_string: true

module Validator
  module_function

  def validate_coordinates(coordinates)
    # Check format: "latitude,longitude" (e.g., "40.7128,-74.0060")
    unless coordinates.match?(/^-?\d+(\.\d+)?,\s*-?\d+(\.\d+)?$/)
      raise ArgumentError, "Invalid coordinates format. Please use 'latitude,longitude'."
    end
  end

  def validate_radius(radius)
    raise ArgumentError, "Radius must be a positive number." unless radius.to_i.positive?
  end

  def validate_query_limit(query_limit)
    raise ArgumentError, "Query limit must be a positive integer." unless query_limit.to_i.positive? || query_limit.nil?
  end

  def validate_type(type)
    # Optional, but if provided, ensure it's a valid string
    unless type.nil? || type.is_a?(String)
      raise ArgumentError, "Type must be a string or nil."
    end
  end
end
