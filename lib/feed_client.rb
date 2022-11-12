class FeedClient

  def fetch_descriptions(config)
    fetch_items(config).map do |item|
      Description.new(
        item.at_xpath('.//description').text,
        Date.parse(item.at_xpath('.//pubDate').text)
      )
    end
  end

  private

  def fetch_items(config)
    feed = RestClient.get(config['feed_url']).to_s
    doc = Nokogiri::XML(feed)
    items = doc.xpath('//item')
    items = items.reject { |item| item.xpath(config['filter']).empty? } if config['filter']
    items
  end

end
