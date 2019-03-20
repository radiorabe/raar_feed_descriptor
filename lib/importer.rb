require 'yaml'
require 'json'
require 'syslog/logger'

require_relative 'description'
require_relative 'raar_client'
require_relative 'feed_client'

class Importer

  def run
    settings['shows'].each_value do |config|
      describe(config)
    end
  rescue Exception => e # rubocop:disable Lint/RescueException
    logger.fatal("#{e}\n#{e.backtrace.join("\n")}")
  end

  private

  def describe(config)
    feed_client.fetch_descriptions(config).each do |description|
      raar_client.update_empty(description, config['raar_id'])
    end
  end

  def feed_client
    @feed_client ||= FeedClient.new
  end

  def raar_client
    @raar_client ||= RaarClient.new(settings['raar'], logger)
  end

  def settings
    @settings ||= YAML.safe_load(File.read(settings_file))
  end

  def settings_file
    File.join(File.join(__dir__), '..', 'config', 'settings.yml')
  end

  def logger
    @logger ||= create_logger.tap do |logger|
      level = settings.dig('importer', 'log_level') || 'info'
      logger.level = Logger.const_get(level.upcase)
    end
  end

  def create_logger
    if settings.dig('importer', 'log') == 'syslog'
      Syslog::Logger.new('raar-feed-descriptor')
    else
      Logger.new(STDOUT)
    end
  end

end
