Rails.application.routes.draw do
  post 'login', to: 'sessions#login'
  get 'me/posts', to: 'posts#my_posts'

  resources :posts
  resources :users, only: [:create]
end
