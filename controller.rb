require 'environment'
require 'sinatra'

helpers do
  def protected!
    if !authorized?
      response['WWW-Authenticate'] = %(Basic realm="You must authenticate")
      throw :halt, [401, "Not authorized\n"]
    end
  end

  def authorized?
    @auth ||=  Rack::Auth::Basic::Request.new(request.env)
    @auth.provided? && @auth.basic? && @auth.credentials && @auth.credentials == ['admin', 'admin']
  end

  @@refreshed_at = Time.at(0)
  STALE_IN = 60 * 60
  def last_refreshed
    if @@refreshed_at == Time.at(0)
      "Never"
    elsif
      @@refreshed_at.to_s
    end
  end
end

get "/" do
  @funnels = Funnel.all
  haml :index
end

get "/:id/:name" do
  f = Funnel.get(params[:id])
  raise Sinatra::NotFound if f.nil? || f.name.downcase != params[:name].downcase

  f.rss
end

get "/delete/:id/:name" do
  protected!

  f = Funnel.get(params[:id])
  raise Sinatra::NotFound if f.nil? || f.name.downcase != params[:name].downcase
  f.destroy

  "gone"
end

get "/generate" do
  h = {:urls => params["urls"]}
  f = Funnel.first(h) || Funnel.create(h)

  redirect "/#{f.id}/#{f.name}"
end

get "/refresh" do
  if @@refreshed_at < Time.now - STALE_IN
    @@refreshed_at = Time.now

    Thread.new {
      Funnel.refresh
    }
  end

  "word"
end

