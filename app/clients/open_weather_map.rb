require 'net/http'
require 'uri'
require 'json'
require 'geocoder'

class OpenWeatherMap
    def get_weather(street_address, city, state, zip)
        address = "#{street_address}, #{city}, #{state}, #{zip}"
        coordinates = get_coordinates(address)

        if coordinates
            weather_data = Rails.cache.read(zip)
            
            if weather_data
                weather_data['cached'] = true
            else
                weather_data = fetch_weather_data(coordinates)
                Rails.cache.write(zip, weather_data, expires_in: 30.minutes)
                weather_data['cached'] = false
            end

            weather_data
        else
            { 'cod' => 400, 'message' => 'Unable to geocode address.' }
        end
    end
  
    private
  
    def get_coordinates(address)
        Geocoder.coordinates(address)
    end
  
    def fetch_weather_data(coordinates)
        lat, lon = coordinates

        uri = URI("http://api.openweathermap.org/data/2.5/weather?lat=#{lat}&lon=#{lon}&units=imperial&appid=#{ENV['OPEN_WEATHER_MAP_API_KEY']}")
        response = Net::HTTP.get(uri)
        JSON.parse(response)
    end
  end
  