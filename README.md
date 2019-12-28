## Step1 Create Rails --api app
`terminal`
```bash
rails new rails-api-token-auth --api -T --database=postgresql
```

## Step2
`terminal`
```bash
rails db:create
```

## Step3 Create User Model
`terminal`
```bash
rails g model User email:string:uniq password_digest:string token:string:uniq
```

`terminal`
```bash
rails db:migrate
```

## Step4 Edit User model
`models/user.rb`
```ruby
class User < ApplicationRecord
  has_secure_password
  has_secure_token

  validates :email, presence: true, uniqueness: true
  validates :password_digest, presence: true
  validates :token, uniqueness: true
end
```

## Step5 Scaffold Post model
`terminal`
```bash
rails g scaffold Post title:string content:text user:references
Running via Spring preloader in process 66303
      invoke  active_record
      create    db/migrate/20191227083511_create_posts.rb
      create    app/models/post.rb
      invoke  resource_route
       route    resources :posts
      invoke  scaffold_controller
      create    app/controllers/posts_controller.rb
```

```bash
rails db:migrate
```

## Step6 Edit Post and User model
`models/post.rb`
```ruby hl_lines="4"
class Post < ApplicationRecord
  belongs_to :user
  
  validates :title, presence: true
end
```

`models/user.rb`
```ruby hl_lines="9"
class User < ApplicationRecord
  has_secure_password
  has_secure_token

  validates :email, presence: true, uniqueness: true
  validates :password_digest, presence: true
  validates :token, uniqueness: true

  has_many :posts
end
```

## Step7 Add Authentication
`controllers/concerns/authable.rb`
```ruby
module Authable
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
```

- include `Authable module` in

`controllers/application_controller.rb`
```ruby
class ApplicationController < ActionController::API
  include Authable
end
```

`app/controllers/posts_controller.rb`
```ruby hl_lines="3"
class PostsController < ApplicationController
  before_action :set_post, only: [:show, :update, :destroy]
  before_action :authenticate_with_token, only: [:create, :update, :destroy]
  ...
end
```

- Install `bycrypt`

`Gemfile`
```ruby
# Use Active Model has_secure_password
gem 'bcrypt', '~> 3.1.7'
```

```bash
bundle
```

- Edit posts_controller
```ruby
def create
  @post = current_user.posts.new(post_params)

  if @post.save
    render json: @post, status: :created
  else
    render json: @post.errors, status: :unprocessable_entity
  end
end
```

## Step8 Register User
`config/routes.rb`
```ruby hl_lines="3"
Rails.application.routes.draw do
  resources :posts
  resources :users, only: [:create]
end
```

`controllers/users_controller.rb`
```ruby
class UserssController < ApplicationController
  def create
    @user = User.new(user_params)

    if @user.save
      render json: @user, status: :created
    else
      render json: @user.errors, status: :unprocessable_entity
    end
  end

  private
    def user_params
      params.permit(:email, :password)
    end
end
```

## Step9 Login
`config/routes.rb`
```ruby
post 'login', to: 'sessions#login'
```

ref: http://railscasts.com/episodes/250-authentication-from-scratch-revised

`app/controllers/sessions_controller.rb`
```ruby
class SessionsController < ApplicationController
  def login
    @user = User.find_by(email: params[:email])

    if @user && @user.authenticate(params[:password])
      render json: @user, status: :ok
    else
      render json: @user.errors, status: :unprocessable_entity
  end
end
```

## Step10 Authorization
`app/controllers/posts_controller.rb`
```ruby
class PostsController < ApplicationController
  ...
  # PATCH/PUT /posts/1
  def update
    authorize(@post)
    if @post.update(post_params)
      render json: @post
    else
      render json: @post.errors, status: :unprocessable_entity
    end
  end

  # DELETE /posts/1
  def destroy
    authorize(@post)
    @post.destroy
  end

  private
    ...
    # https://github.com/varvet/pundit#policies
    def authorize(post)
      @user = post.user
      raise "not allowed to perform this action" unless @user == current_user
    end
end
```

## Step11 Get current_user
`config/routes.rb`
```ruby
get 'me', to: 'users#me'
```

`app/controllers/users_controller.rb`
```ruby
class UsersController < ApplicationController
  before_action :authenticate_with_token, only: [:me]
  ...
  
  def me
    render json: current_user
  end
end
```


## Step12 Get current_user posts
`config/routes.rb`
```ruby
Rails.application.routes.draw do
  ...
  get 'me/posts', to: 'posts#my_posts'

  resources :posts
  resources :users, only: [:create]
end
```

`app/controllers/posts_controller.rb`
```ruby
  before_action :authenticate_with_token, only: [:create, :update, :destroy, :my_posts]
  ...
  def my_posts
    @posts = current_user.posts
    render json: @posts
  end
```

## Step13 Add CORS
Uncomment

`Gemfile`
```ruby
# Use Rack CORS for handling Cross-Origin Resource Sharing (CORS), making cross-origin AJAX possible
gem 'rack-cors'
```

`terminal`
```bash
bundle
```

`config/initializers/cors.rb`
```ruby
# Be sure to restart your server when you modify this file.

# Avoid CORS issues when API is called from the frontend app.
# Handle Cross-Origin Resource Sharing (CORS) in order to accept cross-origin AJAX requests.

# Read more: https://github.com/cyu/rack-cors

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins '*'

    resource '*',
      headers: :any,
      methods: [:get, :post, :put, :patch, :delete, :options, :head]
  end
end
```


## Step14 Wrap params
https://api.rubyonrails.org/v5.2.0/classes/ActionController/ParamsWrapper.html
https://github.com/lynndylanhurley/devise_token_auth/issues/130