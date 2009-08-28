require 'rubygems'
require 'net/http'
require 'hpricot'
require 'rack'
require 'haml'
require 'dm-core'
DataMapper.setup(:default, "sqlite3:///#{Dir.pwd}/test.db")

$:.unshift File.join(File.dirname(__FILE__), "libs", "feed_funnel", "lib")
require 'feed_funnel'

require 'core_ext'
require 'models'

DataMapper.auto_upgrade!

