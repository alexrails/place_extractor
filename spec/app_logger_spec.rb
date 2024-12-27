# frozen_string_literal: true

require_relative '../app/logger'

RSpec.describe AppLogger do
  let(:log_dir) { File.expand_path('../logs', __dir__) }

  before do
    FileUtils.rm_rf(log_dir) # Clean up before running the test
  end

  after do
    FileUtils.rm_rf(log_dir) # Clean up after running the test
  end

  it 'creates a log file in the logs directory' do
    logger = AppLogger.instance
    logger.info('Test log message')

    log_file = File.join(log_dir, 'application.log')
    expect(File).to exist(log_file)
    expect(File.read(log_file)).to include('Test log message')
  end
end
