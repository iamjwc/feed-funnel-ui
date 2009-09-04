# ADD WAY TO EDIT TITLES



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
      "not yet"
    elsif
      diff = Time.now - @@refreshed_at
      "#{(diff / 60).to_i} minutes ago"
    end
  end

  def with_valid_feed(f, &b)
    if f.nil? || f.title.to_s.downcase != params[:clean_url].to_s.downcase
      not_found
    else
      b.call(f)
    end
  end
  
  def host
    request.host + (":#{request.port}" if request.port)
  end
  
end

get "/" do
  @funnels = Funnel.all
  haml :index
end

get "/all" do
  @funnels = Funnel.all
  haml :all
end

get "/:id/:clean_url.:format" do
  if @funnel = Funnel.get(params[:id])
    content_type "application/rss+xml"
    @funnel.rss
  else
    not_found
  end
end

post "/update/:id/:clean_url" do
  protected!
  
  @feed = Funnel.get(params[:id])
  @feed.title = params[:feed][:title] if params[:feed][:title]
  @feed.clean_url = params[:feed][:clean_url] if params[:feed][:clean_url]
  @feed.rss = @feed.refresh(:title => @feed.title)
  @feed.save
  @feed = Funnel.get(params[:id])
  
  redirect "/all"
end

get "/edit/:id/:clean_url" do
  protected!

  @feed = Funnel.get(params[:id])

  haml :edit
end

get "/delete/:id/:clean_url" do
  protected!

  with_valid_feed(Funnel.get(params[:id])) do |f|
    f.destroy
    redirect '/'
  end
end

post "/generate" do
  h = {:urls => params["urls"]}
  f = Funnel.first(h) || (Funnel.create(h) rescue nil)

  if f && !f.rss.to_s.strip.empty? && !f.clean_url.to_s.empty?
    url = "http://#{host}/#{f.id}/#{f.clean_url}.xml"
    request.xhr? ? "#{url}|#{f.url}|#{f.img}" : redirect(url)
  else
    # Get rid of blank submissions
    f.destroy if f
    request.xhr? ? "" : redirect('/')
  end
end

get "/refresh" do
  if @@refreshed_at < Time.now - STALE_IN
    @@refreshed_at = Time.now

    Thread.new { Funnel.refresh }
  end

  redirect '/'
end

