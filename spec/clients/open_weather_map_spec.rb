require 'rails_helper'
require 'webmock/rspec'

RSpec.describe OpenWeatherMap do
  let(:weather_client) { OpenWeatherMap.new }
  let(:valid_address) { '123 Street, New York, NY, 12345' }
  let(:valid_zip) { '12345' }
  let(:valid_coordinates) { [40.7128, -74.0060] } # coordinates for New York, NY
  let(:invalid_address) { 'Fake Street, Imaginary City, ZZ, 00000' }

  before do
    allow(Geocoder).to receive(:coordinates).with(valid_address).and_return(valid_coordinates)
    allow(Geocoder).to receive(:coordinates).with(invalid_address).and_return(nil)
  end

  context 'when a valid address is provided' do
    let(:weather_data) { { 'cod' => 200, 'message' => 'success', 'cached' => false } }

    before do
      stub_request(:get, /api.openweathermap.org/).to_return(body: weather_data.to_json)
    end

    it 'returns weather data' do
      result = weather_client.get_weather('123 Street', 'New York', 'NY', valid_zip)
      expect(result).to eq(weather_data)
    end

    context 'when weather data is already cached' do
      let(:cached_weather_data) { weather_data.merge('cached' => true) }

      before do
        Rails.cache.write(valid_zip, cached_weather_data, expires_in: 30.minutes)
      end

      it 'uses the cached weather data' do
        result = weather_client.get_weather('123 Street', 'New York', 'NY', valid_zip)
        expect(result).to eq(cached_weather_data)
      end
    end
  end

  context 'when an invalid address is provided' do
    it 'returns an error' do
      result = weather_client.get_weather('Fake Street', 'Imaginary City', 'ZZ', '00000')
      expect(result).to eq({ 'cod' => 400, 'message' => 'Unable to geocode address.' })
    end
  end
end
