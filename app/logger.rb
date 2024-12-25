require 'logger'

class AppLogger
  def self.instance
    @logger ||= Logger.new(File.join(__dir__, '../logs', 'application.log'), 'daily')
  end
end
