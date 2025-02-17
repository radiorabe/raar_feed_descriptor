class RaarClient

  JSON_API_CONTENT_TYPE = 'application/vnd.api+json'.freeze

  attr_reader :settings, :logger

  def initialize(settings, logger)
    @settings = settings
    @logger = logger
  end

  def fetch_show(title)
    title = stem_title(title)
    search_shows(title)
      .find { |show| same_title?(show, title) }
  end

  def fetch_broadcast(show_id, date)
    response = raar_request(:get,
                            broadcast_date_url(show_id, date),
                            nil,
                            accept: JSON_API_CONTENT_TYPE)
    json = JSON.parse(response.body)
    json['data'].first
  end

  def update_broadcast(broadcast, details)
    raar_request(:patch,
                 "broadcasts/#{broadcast['id']}",
                 update_payload(broadcast, details).to_json,
                 content_type: JSON_API_CONTENT_TYPE,
                 accept: JSON_API_CONTENT_TYPE)
  end

  private

  def search_shows(title)
    response = raar_request(
      :get,
      'shows',
      nil,
      params: { q: title },
      accept: JSON_API_CONTENT_TYPE
    )
    json = JSON.parse(response.body)
    json['data']
  end

  def broadcast_date_url(show_id, date)
    year = date.year
    month = rjust(date.month)
    day = rjust(date.day)
    "shows/#{show_id}/broadcasts/#{year}/#{month}/#{day}"
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

  def same_title?(show, title)
    stem_title(show['attributes']['name']) == title
  end

  def stem_title(string)
    string.downcase.gsub(/[^a-z0-9]/, ' ')
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
      .transform_keys(&:to_sym)
  end

  def raar_url
    settings['url']
  end

end
