require 'yaml'
require 'json'

require_relative 'directus_post'
require_relative 'directus_client'
require_relative 'raar_client'

class Importer

  MONTH_NAMES = %w[
    nil
    januar
    februar
    märz
    april
    mai
    juni
    juli
    august
    september
    oktober
    november
    dezember
  ].freeze

  def run
    # RestClient.log = STDOUT
    directus_client.fetch_posts.each do |post|
      update_empty(post) if post.time <= now && include?(post)
    end
  rescue Exception => e # rubocop:disable Lint/RescueException
    logger.fatal("#{e}\n#{e.backtrace.join("\n")}")
  end

  private

  def include?(post)
    filter = show_filter(post.show_slug)
    return true unless filter

    send(filter, post).tap do |include|
      logger.debug("Excluded post #{post.show}: '#{post.title}' by filter #{filter}") unless include
    end
  end

  def show_filter(show)
    @show_filters ||= {}
    @show_filters.fetch(show) do
      @show_filters[show] = settings.dig('importer', 'filters', show)
    end
  end

  def month_in_title(post)
    post.title.downcase.include?(MONTH_NAMES[post.time.month])
  end

  def update_empty(post)
    return unless show_id(post.show)

    broadcast = fetch_closest_broadcast(show_id(post.show), post.date)
    if broadcast && broadcast['attributes']['details'].to_s.strip.empty?
      raar_client.update_broadcast(broadcast, post.content) unless dry_run?
      logger.info("Updated description for broadcast #{post.show} at #{broadcast['attributes']['started_at']}")
      logger.debug(post.content)
    elsif !broadcast
      logger.debug("No broadcast of '#{post.show}' found before or after #{post.date}")
      logger.debug(post.content)
    end
  end

  def show_id(name)
    @show_ids ||= {}
    @show_ids.fetch(name) do
      @show_ids[name] = fetch_show_id(name)
    end
  end

  def fetch_show_id(name)
    show = raar_client.fetch_show(name)
    if show
      show.fetch('id')
    else
      logger.debug("No show found for '#{name}'")
      nil
    end
  end

  def fetch_closest_broadcast(show_id, date)
    adjacent_days.each do |offset|
      day = date + offset
      broadcast = raar_client.fetch_broadcast(show_id, day)
      return broadcast if broadcast
    end
    nil
  end

  def adjacent_days
    @adjacent_days ||= settings.dig('importer', 'adjacent_days') || [0]
  end

  def dry_run?
    return @dry_run if defined?(@dry_run)

    @dry_run = settings.dig('importer', 'dry_run')
  end

  def directus_client
    @directus_client ||= DirectusClient.new(settings['directus'])
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
      require 'syslog/logger'
      Syslog::Logger.new('raar-feed-descriptor').tap do |logger|
        logger.formatter = proc { |severity, _datetime, _prog, msg|
          "#{Logger::SEV_LABEL[severity]} #{msg}"
        }
      end
    else
      Logger.new($stdout)
    end
  end

  def now
    @now ||= Time.now
  end

end
