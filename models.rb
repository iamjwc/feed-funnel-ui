FIELDS = {
  :published_date => lambda {|i| (i.h % :pubDate).inner_text },
  :description    => lambda {|i| (i.h % :description).inner_text.dehtmlify },
  :title          => lambda {|i| (i.h % :title).inner_text },
  :enclosure_url  => lambda {|i| (i.h % :enclosure)[:url].inner_text }
}

class Funnel
  include DataMapper::Resource
 
  # The Serial type provides auto-incrementing primary keys
  property :id,         Serial
  property :title,      Text,     :lazy => false
  property :clean_url,  Text,     :lazy => false
  property :urls,       Text,     :lazy => false
  property :rss,        Text,     :lazy => false, :default => Proc.new {|row, rss| row.refresh }
  property :created_at, DateTime,                 :default => Proc.new {|row, created_at| Time.now }

  before :save do
    self.title     = name if self.title.nil?
    self.clean_url = title if self.clean_url.nil?
  end

  def urls
    (@urls || "").split
  end

  def name
    $1.urlify if self.rss =~ /<title>([^<]*)<\/title>/im
  end

  def img
    # <itunes:image href="http://bitcast-a.bitgravity.com/revision3/images/shows/coop/coop.jpg" />
    if self.rss =~ /<itunes:image ([^>]*)/im
      $1 if $1 =~ /href=["']([^"']*)/
    end
  end

  def url
    $1.strip if self.rss =~ /<link>([^<]*)<\/link>/im
  end

  def self.refresh
    self.all.each do |f|
      f.attribute_set :rss, f.refresh(:title => f.title)
      f.save
    end
  end

  def refresh(opts={})
    opts[:matchers] = [ FeedFunnel::DateProximityMatcher.new(&FIELDS[:published_date]) ]
    opts[:feeds]    = self.feeds.tail
    opts[:title]    ||= self.title
    FeedFunnel::Funnel.new(self.feeds.head, opts).GO!.to_s
  end

  def feeds
    @feeds ||= self.urls.map {|url| FeedFunnel::Feed.new fetch(url) }
  end

  def fetch(url)
    Net::HTTP.get URI.parse(url)
  end
end

