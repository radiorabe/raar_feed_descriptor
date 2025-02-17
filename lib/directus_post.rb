class DirectusPost

  attr_reader :title, :content, :time, :show_slug
  attr_accessor :show

  def initialize(json)
    @title = json['title']
    @show_slug = json['program']
    @content = extract_content(json)
    @time = Time.parse(json['date_published'])
  end

  def date
    time.to_date
  end

  private

  def extract_content(json)
    json['content']['content'].map do |c|
      next unless c['content']
      "<p>#{c['content'].map { |d| d['text'] || '<br/>' }.join}</p>"
    end.join
  end

end
