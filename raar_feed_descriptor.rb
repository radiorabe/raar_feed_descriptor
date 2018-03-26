#!/usr/bin/env ruby

require 'rubygems'
require 'bundler/setup'
Bundler.require(:default)
require 'yaml'
require 'json'

class RaarFeedDescriptor

  JSON_API_CONTENT_TYPE = 'application/vnd.api+json'.freeze

  def run
    settings['shows'].each_value do |config|
      describe(config)
    end
  end

  private

  def describe(config)
    fetch_items(config).each do |item|
      update_empty(item, config['raar_id'])
    end
  end

  def fetch_items(config)
    fetch_feed_items(config).map do |item|
      {
        date: Date.parse(item.at_xpath('.//pubDate').text),
        description: item.at_xpath('.//description').text
      }
    end
  end

  def fetch_feed_items(config)
    feed = RestClient.get(config['feed_url']).to_s
    doc = Nokogiri::XML(feed)
    items = doc.xpath('//item')
    if config['filter']
      items = items.reject { |item| item.xpath(config['filter']).empty? }
    end
    items
  end

  def update_empty(item, show_id)
    broadcast = fetch_broadcast(item, show_id)
    if broadcast && broadcast['attributes']['details'].to_s.strip.empty?
      update_broadcast(broadcast, item[:description])
    end
  end

  def fetch_broadcast(item, show_id)
    url = broadcast_url(show_id, item[:date])
    response = RestClient.get(url, accept: JSON_API_CONTENT_TYPE)
    json = JSON.parse(response.body)
    json['data'].first
  end

  def broadcast_url(show_id, date)
    year = date.year
    month = rjust(date.month)
    day = rjust(date.day)

    "#{raar_url}/shows/#{show_id}/broadcasts/#{year}/#{month}/#{day}" \
      "?api_token=#{api_token}"
  end

  def update_broadcast(broadcast, description)
    url = "#{raar_url}/broadcasts/#{broadcast['id']}"
    RestClient.patch(url,
                     update_payload(broadcast, description).to_json,
                     content_type: JSON_API_CONTENT_TYPE,
                     accept: JSON_API_CONTENT_TYPE)
  end

  def update_payload(broadcast, description)
    {
      api_token: api_token,
      data: {
        id: broadcast['id'],
        type: broadcast['type'],
        attributes: {
          details: description
        }
      }
    }
  end

  def api_token
    @api_token ||= login_user['api_token']
  end

  def login_user
    credentials = {
      username: settings['raar']['username'],
      password: settings['raar']['password']
    }
    response = RestClient.post("#{raar_url}/login", credentials)
    json = JSON.parse(response.body)
    json['data']['attributes']
  end

  def rjust(val)
    val.to_s.rjust(2, '0')
  end

  def raar_url
    settings['raar']['url']
  end

  def settings
    @settings ||= YAML.safe_load(File.read(settings_file))
  end

  def settings_file
    File.join(home, 'config', 'settings.yml')
  end

  def home
    File.join(__dir__)
  end

end

RaarFeedDescriptor.new.run
