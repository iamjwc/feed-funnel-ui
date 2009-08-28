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
      diff = Time.now - @@refreshed_at
      "#{(diff / 60).to_i} minutes ago"
    end
  end

  def with_valid_feed(f, &b)
    if f.nil? || f.name.to_s.downcase != params[:name].to_s.downcase
      not_found
    else
      b.call(f)
    end
  end
end

get "/" do
  @funnels = Funnel.all
  haml :index
end

get "/:id/:name" do
  with_valid_feed(Funnel.get(params[:id])) do |f|
    content_type "application/rss+xml"
    f.rss
  end
end

get "/delete/:id/:name" do
  protected!

  with_valid_feed(Funnel.get(params[:id])) do |f|
    f.destroy
    redirect '/'
  end
end

get "/generate" do
  begin
    h = {:urls => params["urls"]}
    f = Funnel.first(h) || Funnel.create(h)
  
    if f.rss.to_s.strip.empty?
      # Get rid of blank submissions
      f.destroy
      redirect '/'
    else
      redirect "/#{f.id}/#{f.name}"
    end
  rescue
    redirect '/'
  end
end

get "/refresh" do
  if @@refreshed_at < Time.now - STALE_IN
    @@refreshed_at = Time.now

    Thread.new { Funnel.refresh }
  end

  redirect '/'
end

