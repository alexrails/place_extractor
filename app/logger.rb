# frozen_string_literal: true

require 'logger'
require 'fileutils'

class AppLogger
  def self.instance
    log_dir = File.join(__dir__, '../logs')
    FileUtils.mkdir_p(log_dir)
    @logger ||= Logger.new(File.join(log_dir, 'application.log'), 'daily')
  end
end
