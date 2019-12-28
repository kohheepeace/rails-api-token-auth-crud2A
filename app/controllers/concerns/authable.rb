module Authable
  # Ref: https://github.com/kurenn/market_place_api/blob/chapter10/app/controllers/concerns/authenticable.rb
  def current_user
    @current_user ||= User.find_by(token: bearer_token) 
  end

  def authenticate_with_token
    render json: { errors: "Please Log in." }, status: :unauthorized unless user_signed_in?
  end

  def user_signed_in?
    current_user.present?
  end

  # Find bearer token from request
  # https://stackoverflow.com/questions/44323531/how-to-get-bearer-token-passed-through-header-in-rails
  def bearer_token
    pattern = /^Bearer /
    header  = request.headers['Authorization']
    header.gsub(pattern, '') if header && header.match(pattern)
  end
end