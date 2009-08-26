RACK_ROOT = File.dirname(__FILE__)

require File.join(RACK_ROOT, 'controller.rb')

set :environment, :development
set :root, RACK_ROOT
disable :run

run Sinatra::Application

