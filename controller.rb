require 'environment'
require 'sinatra'

get "/" do
  @funnels = Funnel.all
  haml :index
end

get "/:id/:name" do
  f = Funnel.get(params[:id])
  raise Sinatra::NotFound if f.nil? || f.name.downcase != params[:name].downcase

  f.rss
end

get "/generate" do
  h = {:urls => params["urls"]}
  f = Funnel.first(h) || Funnel.create(h)

  redirect "/#{f.id}/#{f.name}"
end

@@refreshed_at = Time.at(0)
STALE_IN = 60 * 60
get "/refresh" do
  if @@refreshed_at < Time.now - STALE_IN
    @@refreshed_at = Time.now

    Funnel.refresh
  end

  "word"
end

