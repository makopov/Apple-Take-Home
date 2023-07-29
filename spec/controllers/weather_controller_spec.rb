require 'rails_helper'

RSpec.describe WeatherController, type: :controller do
  let(:valid_attributes) {
    {
      street_address: '123 Street',
      city: 'New York',
      state: 'NY',
      zip: '10001'
    }
  }

  let(:invalid_attributes) {
    {
      street_address: '',
      city: '',
      state: '',
      zip: ''
    }
  }

  let(:valid_session) { {} }

  describe "POST #create" do
    context "with valid parameters" do
      before do
        weather_data = {
          'cod' => 200,
          'message' => 'success',
          'cached' => true
        }
        allow_any_instance_of(OpenWeatherMap).to receive(:get_weather).and_return(weather_data)

        stub_request(:get, /nominatim.openstreetmap.org/)
          .to_return(status: 200, body: '[{"lat": "40.71427", "lon": "-74.00597"}]')
      end

      it "creates a new Weather object" do
        post :create, params: valid_attributes, session: valid_session
        expect(response).to redirect_to(show_weather_path(zip: valid_attributes[:zip], cached: true))
      end
    end

    context "with invalid parameters" do
      before do
        weather_data = {
          'cod' => 400,
          'message' => 'Unable to geocode address.',
          'cached' => false
        }
        allow_any_instance_of(OpenWeatherMap).to receive(:get_weather).and_return(weather_data)

        stub_request(:get, /nominatim.openstreetmap.org/)
          .to_return(status: 200, body: '[{"lat": "40.71427", "lon": "-74.00597"}]')
      end

      it "renders a unsuccessful response" do
        post :create, params: invalid_attributes, session: valid_session
        expect(flash[:error]).to be_present
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "GET #show" do
    context "with valid parameters" do
      before do
        weather_data = {
          'cod' => 200,
          'message' => 'success',
          'main' => {
            'temp' => 75.5,
            'temp_min' => 70,
            'temp_max' => 80
          },
          'sys' => {
            'sunrise' => Time.now.to_i - 4 * 60 * 60,
            'sunset' => Time.now.to_i + 4 * 60 * 60
          }
        }
        Rails.cache.write(valid_attributes[:zip], weather_data, expires_in: 30.minutes)
      end

      it "returns a success response" do
        get :show, params: {zip: valid_attributes[:zip], cached: true}, session: valid_session
        expect(response).to be_successful
      end
    end
  end
end
