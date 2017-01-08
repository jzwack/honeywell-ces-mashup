require 'soda/client'
require 'rest-client'
require 'sinatra'
require 'base64'

enable :sessions
## Settings Block
apiKey = ""
apiSecret = ""
appToken = ""
redirectUri = ""
soda_domain = ""
## 


get '/' do
    if session[:access_token]
        redirect to('/select')
    else
        redirect to('/login')
    end
end

## Login starts Oauth
get '/login' do
    redirect "https://api.honeywell.com/oauth2/authorize?client_id=#{apiKey}&redirect_uri=#{redirectUri}&response_type=code"
end

## OAuth Redirect
get '/redirect' do
    auth = Base64.strict_encode64(apiKey + ':' + apiSecret)
    code = params[:code]
    body = "grant_type=authorization_code&code=#{code}&redirect_uri=#{redirectUri}"
    response = JSON.parse(RestClient.post('https://api.honeywell.com/oauth2/token', body, {:authorization => 'Basic ' + auth, :content_type => 'application/x-www-form-urlencoded'}))
    access_token = response['access_token']
    puts "got token " + access_token
    session[:access_token] = access_token
    redirect to('/select')
end

## Get all devices that are schedule capable (LCC devices) along with selection data for power provider and date
get '/select' do
    client = SODA::Client.new({:domain => soda_domain, :app_token => appToken})
    @facility_results = client.get("kte4-s45x", {:$select => "facility_name", :$group => 'facility_name'})
    @date_results = client.get("kte4-s45x", {:$select => "date", :$group => 'date', :$order => 'date ASC'})
    @devices = Array.new
    @locations_data = Array.new
    locations = JSON.parse(RestClient.get("https://api.honeywell.com/v2/locations?apikey=#{apiKey}", {:authorization => "Bearer " + session[:access_token]}))
    locations.each do |location| 
        @locations_data.push(location)
        location['devices'].each do |device|
            if device['deviceID'].start_with?("LCC-")
                @devices.push(device)
            else
                next
            end
        end
    end
    erb :select
end

## Checks to see if selected date power generation is more or less than the average, if it's more we change the schedule to use less energy

post '/optimize' do
    puts params[:location]
    client = SODA::Client.new({:domain => soda_domain, :app_token => appToken})
    generated_for_date = client.get("kte4-s45x", {:$select => "facility_name, date, generated", :$group => 'facility_name, date, generated', :facility_name => params[:facility], :date => params[:date]})
    avg_for_all = client.get("kte4-s45x", {:$select => "facility_name, AVG(generated)", :$group => 'facility_name', :facility_name => params[:facility]})
    selected_date = generated_for_date.first.generated
    total_avg = avg_for_all.first.AVG_generated
    puts "Generated for selected date: " + selected_date
    puts "avg for all dates: " + total_avg
    if selected_date > total_avg
        "Power levels are fine, no need to change the schedule!"
    else
        redirect to("/optimize?saving=true&deviceId=#{params[:device]}&locationId=#{params[:location]}")
    end
end

## This GET is what actually gets the schedule and edits it.
get '/optimize' do
    if params[:saving] = true
        schedule = JSON.parse(RestClient.get("https://api.honeywell.com/v2/devices/schedule/#{params[:deviceId]}?apikey=#{apiKey}&locationId=#{params[:locationId]}&type=regular", {:authorization => "Bearer " + session[:access_token]}))
        schedule['timedSchedule']['days'].each do |day|
            day['periods'].each do |period|
                period['heatSetPoint'] = period['heatSetPoint'] - 2
                period['coolSetPoint'] = period['coolSetPoint'] + 2
            end
        end
        newSchedule = schedule.to_json
        response = RestClient.post("https://api.honeywell.com/v2/devices/schedule/#{params[:deviceId]}?apikey=#{apiKey}&locationId=#{params[:locationId]}&type=regular", newSchedule, {:authorization => "Bearer " + session[:access_token], :content_type => 'application/json'})
        "Optimized for high energy cost"
    else
        "Normal usage is OK!"
    end
end

## Logout and clear the session.
get '/logout' do
    session.clear
    redirect to('/')
end

