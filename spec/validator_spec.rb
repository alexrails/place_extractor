# frozen_string_literal: true

require_relative '../app/validator'

RSpec.describe Validator do
  describe '.validate_coordinates' do
    it 'raises an error for invalid coordinate formats' do
      expect { described_class.validate_coordinates('invalid_format') }
        .to raise_error(ArgumentError, "Invalid coordinates format. Please use 'latitude,longitude'.")
    end

    it 'does not raise an error for valid coordinate formats' do
      expect { described_class.validate_coordinates('40.7128,-74.0060') }.not_to raise_error
      expect { described_class.validate_coordinates('-23.5505,-46.6333') }.not_to raise_error
    end
  end

  describe '.validate_radius' do
    it 'raises an error for non-positive radius' do
      expect { described_class.validate_radius(0) }
        .to raise_error(ArgumentError, 'Radius must be a positive number.')
      expect { described_class.validate_radius(-5) }
        .to raise_error(ArgumentError, 'Radius must be a positive number.')
    end

    it 'does not raise an error for positive radius' do
      expect { described_class.validate_radius(10) }.not_to raise_error
      expect { described_class.validate_radius(1.5) }.not_to raise_error
    end
  end

  describe '.validate_query_limit' do
    it 'raises an error for non-positive query limits' do
      expect { described_class.validate_query_limit(0) }
        .to raise_error(ArgumentError, 'Query limit must be a positive integer.')
      expect { described_class.validate_query_limit(-3) }
        .to raise_error(ArgumentError, 'Query limit must be a positive integer.')
    end

    it 'does not raise an error for positive query limits or nil' do
      expect { described_class.validate_query_limit(5) }.not_to raise_error
      expect { described_class.validate_query_limit(nil) }.not_to raise_error
    end
  end

  describe '.validate_type' do
    it 'raises an error for invalid types' do
      expect { described_class.validate_type(123) }
        .to raise_error(ArgumentError, 'Type must be a string or nil.')
      expect { described_class.validate_type([]) }
        .to raise_error(ArgumentError, 'Type must be a string or nil.')
    end

    it 'does not raise an error for valid types' do
      expect { described_class.validate_type('place') }.not_to raise_error
      expect { described_class.validate_type(nil) }.not_to raise_error
    end
  end
end
