class RaarClient

  JSON_API_CONTENT_TYPE = 'application/vnd.api+json'.freeze

  attr_reader :settings, :logger

  def initialize(settings, logger)
    @settings = settings
    @logger = logger
  end

  def update_empty(description, show_id)
    broadcast = fetch_broadcast(description, show_id)
    if broadcast && broadcast['attributes']['details'].to_s.strip.empty?
      update_broadcast(broadcast, description.text)
      logger.info("Updated description for Show##{show_id} " \
                  "at #{description.date}")
    end
  end

  private

  def fetch_broadcast(description, show_id)
    response = raar_request(:get,
                            broadcast_date_url(show_id, description.date),
                            params: { api_token: api_token },
                            accept: JSON_API_CONTENT_TYPE)
    json = JSON.parse(response.body)
    json['data'].first
  end

  def broadcast_date_url(show_id, date)
    year = date.year
    month = rjust(date.month)
    day = rjust(date.day)
    "shows/#{show_id}/broadcasts/#{year}/#{month}/#{day}"
  end

  def update_broadcast(broadcast, details)
    raar_request(:patch,
                 "broadcasts/#{broadcast['id']}",
                 update_payload(broadcast, details).to_json,
                 content_type: JSON_API_CONTENT_TYPE,
                 accept: JSON_API_CONTENT_TYPE)
  end

  def update_payload(broadcast, details)
    {
      api_token: api_token,
      data: {
        id: broadcast['id'],
        type: broadcast['type'],
        attributes: {
          details: details
        }
      }
    }
  end

  def api_token
    @api_token ||= login_user['api_token']
  end

  def login_user
    credentials = {
      username: settings['username'],
      password: settings['password']
    }
    response = raar_request(:post, 'login', credentials)
    json = JSON.parse(response.body)
    json['data']['attributes']
  end

  def raar_request(method, path, payload = nil, headers = {})
    RestClient::Request.execute(
      http_options.merge(
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

  def http_options
    @http_options ||=
      (settings['options'] || {})
      .each_with_object({}) do |(key, val), hash|
        hash[key.to_sym] = val
      end
  end

  def raar_url
    settings['url']
  end

end
