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
  property :urls,       Text,     :lazy => false
  property :rss,        Text,     :lazy => false, :default => Proc.new {|row, rss| row.refresh }
  property :created_at, DateTime,                 :default => Proc.new {|row, created_at| Time.now }

  def urls
    (@urls || "").split
  end

  def name
    $1.urlify if self.rss =~ /<title>([^<]*)<\/title>/im
  end

  def self.refresh
    self.all.each {|f| f.refresh }
  end

  def refresh
    self.attribute_set :rss, FeedFunnel::Funnel.new(self.feeds.head,
      :matchers => [ FeedFunnel::DateProximityMatcher.new(&FIELDS[:published_date]) ],
      :feeds => self.feeds.tail
    ).GO!.to_s

    self.save
  end

  def feeds
    @feeds ||= self.urls.map {|url| FeedFunnel::Feed.new fetch(url) }
  end

  def fetch(url)
    Net::HTTP.get URI.parse(url)
  end
end

