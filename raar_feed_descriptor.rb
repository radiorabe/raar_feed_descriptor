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
    response = raar_request(:get,
                            broadcast_url(show_id, item[:date]),
                            params: { api_token: api_token },
                            accept: JSON_API_CONTENT_TYPE)
    json = JSON.parse(response.body)
    json['data'].first
  end

  def broadcast_url(show_id, date)
    year = date.year
    month = rjust(date.month)
    day = rjust(date.day)
    "shows/#{show_id}/broadcasts/#{year}/#{month}/#{day}"
  end

  def update_broadcast(broadcast, description)
    raar_request(:patch,
                 "broadcasts/#{broadcast['id']}",
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
    response = raar_request(:post, 'login', credentials)
    json = JSON.parse(response.body)
    json['data']['attributes']
  end

  def raar_request(method, path, payload = nil, headers = {})
    RestClient::Request.execute(
      raar_http_options.merge(
        method: method,
        payload: payload,
        url: "#{raar_url}/#{path}",
        headers: headers
      )
    )
  end

  def rjust(val)
    val.to_s.rjust(2, '0')
  end

  def raar_http_options
    @raar_http_options ||=
      (settings['raar']['options'] || {})
        .each_with_object({}) do |(key, val), hash|
          hash[key.to_sym] = val
        end
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
