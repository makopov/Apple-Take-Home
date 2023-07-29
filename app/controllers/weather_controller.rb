class WeatherController < ApplicationController

  def new
    # no-op
  end

  def create
    weather_data = fetch_weather(params[:street_address], params[:city], params[:state], params[:zip])
  
    if weather_data['cod'] != 200
      flash[:error] = "Error: #{weather_data['message']}"
      redirect_to root_path
    else
      @cached = weather_data['cached']
      
      redirect_to show_weather_path(zip: params[:zip], cached: @cached)
    end
  rescue StandardError => e
    flash[:error] = "Error: #{e.message}"
    redirect_to root_path
  end

  def show
    zip = params[:zip]
    @cached = params[:cached] == 'true'

    weather_data = Rails.cache.fetch(zip)

    if weather_data
      @temperature = weather_data['main']['temp']
      @low = weather_data['main']['temp_min']
      @high = weather_data['main']['temp_max']
      @sunrise = Time.at(weather_data['sys']['sunrise'])
      @sunset = Time.at(weather_data['sys']['sunset'])
    else
      flash[:error] = 'No cached weather data available for this zip code.'
      redirect_to root_path
    end
  end  

  private

  def fetch_weather(street_address, city, state, zip)
    weather_client = OpenWeatherMap.new
    weather_data = weather_client.get_weather(street_address, city, state, zip)
    weather_data
  end
end
