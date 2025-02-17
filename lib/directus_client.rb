class DirectusClient

  attr_reader :settings

  def initialize(settings)
    @settings = settings
  end

  def fetch_posts
    data = fetch_data(settings['posts'])
    data.lazy.map do |json|
      DirectusPost.new(json).tap do |post|
        post.show = fetch_show(post.show_slug)&.fetch('name')
      end
    end
  end

  def fetch_show(slug)
    fetch_data(settings['show'].gsub("%slug%", slug)).first
  end

  private

  def fetch_data(url)
    response = RestClient.get(url)
    JSON.parse(response.body)['data']
  end

end
