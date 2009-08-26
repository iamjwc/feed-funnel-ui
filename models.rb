$:.unshift File.join(File.dirname(__FILE__), "libs", "feed_funnel", "lib")
require "feed_funnel"
require 'net/http'
require 'dm-core'

DataMapper.setup(:default, "sqlite3:///#{Dir.pwd}/test.db")

class String
  def strip_html
    self.gsub(/&gt;/, ">").gsub(/&lt;/, "<").gsub(/<[^>]*>/m, "").gsub(/\W+/, " ").gsub(/&[a-z]{0,4};/i, "")
  end
end

class Array
  alias :head :first

  def tail
    self[1..-1]
  end
end

class Funnel
  include DataMapper::Resource
 
  # The Serial type provides auto-incrementing primary keys
  property :id,         Serial
  property :urls,       Text,     :lazy => false
  property :rss,        Text,     :lazy => false, :default => Proc.new {|row, rss| row.refresh }
  property :created_at, DateTime, :default => Proc.new {|row, created_at| Time.now }

  def urls
    (@urls || "").split
  end

  def feeds
    @feeds ||= self.urls.map {|url| FeedFunnel::Feed.new fetch(url) }
  end

  def self.refresh
    self.all.each do |f|
      f.attribute_set :rss, f.refresh
      f.save
    end
  end

  def refresh
    FeedFunnel::Funnel.new(self.feeds.head,
      :matchers => [ FeedFunnel::DateProximityMatcher.new {|i| (i.h % :pubDate).inner_text } ],
     # :matchers => [FeedFunnel::LevenshteinMatcher.new {|i| (i.h % :description).inner_text.strip_html }],
      :feeds => self.feeds.tail
    ).GO!.to_s
  end

  def fetch(url)
    Net::HTTP.get URI.parse(url)
  end
end

DataMapper.auto_upgrade!
