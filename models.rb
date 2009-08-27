$:.unshift File.join(File.dirname(__FILE__), "libs", "feed_funnel", "lib")
require "feed_funnel"
require 'hpricot'
require 'net/http'
require 'dm-core'

DataMapper.setup(:default, "sqlite3:///#{Dir.pwd}/test.db")

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

  def feeds
    @feeds ||= self.urls.map {|url| FeedFunnel::Feed.new fetch(url) }
  end

  def name
    $1.urlify if self.rss =~ /<title>([^<]*)<\/title>/im
  end

  def self.refresh
    self.all.each do |f|
      f.attribute_set :rss, f.refresh
      f.save
    end
  end

  def refresh
    FeedFunnel::Funnel.new(self.feeds.head,
      :matchers => [ FeedFunnel::DateProximityMatcher.new(&FIELDS[:published_date]) ],
      :feeds => self.feeds.tail
    ).GO!.to_s
  end

  def fetch(url)
    Net::HTTP.get URI.parse(url)
  end
end

DataMapper.auto_upgrade!
