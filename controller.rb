require 'rubygems'
require 'hpricot'
require 'rack'
require 'haml'
require 'sinatra'

$:.unshift File.join(File.dirname(__FILE__), "libs", "feed_funnel", "lib")
require "feed_funnel"

require 'net/http'


get "/" do
  haml :index
end

get "/generate" do
  urls = params["urls"].split
  feeds = urls.map {|url| FeedFunnel::Feed.new fetch(url) }

  p urls.first
  p [urls[1..-1]].flatten

  first = feeds.first
  rest  = [feeds[1..-1]].flatten

  #FeedFunnel::Funnel.new(first,
  #  :matchers => [ FeedFunnel::DateProximityMatcher.new {|i| d = (i.h % :pubDate).inner_text; puts d; d } ],
  #  :feeds    => rest
  #).GO!.to_s

  FeedFunnel::Funnel.new(first,
    :matchers => [ FeedFunnel::DateProximityMatcher.new {|i| d = (i.h % :pubDate).inner_text; puts d; d } ],
   # :matchers => [FeedFunnel::LevenshteinMatcher.new {|i| (i.h % :description).inner_text.strip_html }],
    :feeds => rest
  ).GO!.to_s
end

class String
  def strip_html
    self.gsub(/&gt;/, ">").gsub(/&lt;/, "<").gsub(/<[^>]*>/m, "").gsub(/\W+/, " ").gsub(/&[a-z]{0,4};/i, "")
  end
end

def fetch(url)
  Net::HTTP.get URI.parse(url)
end

