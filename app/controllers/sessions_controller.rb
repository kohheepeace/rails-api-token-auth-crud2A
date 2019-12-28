class SessionsController < ApplicationController
  def login
    @user = User.find_by(email: params[:email])

    if @user && @user.authenticate(params[:password])
      render json: @user, status: :ok
    else
      render json: @user.errors, status: :unprocessable_entity
  end
end
