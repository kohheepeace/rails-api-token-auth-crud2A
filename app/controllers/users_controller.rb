class UsersController < ApplicationController
  before_action :authenticate_with_token, only: [:me]

  def create
    @user = User.new(user_params)

    if @user.save
      render json: { token: @user.token }, status: :created
    else
      render json: @user.errors, status: :unprocessable_entity
    end
  end

  def me
    render json: current_user
  end

  private
    def user_params
      params.require(:user).permit(:email, :password)
    end
end
