class PostsController < ApplicationController
  before_action :set_post, only: [:show, :update, :destroy]
  before_action :authenticate_with_token, only: [:create, :update, :destroy, :my_posts]

  # GET /posts
  def index
    @posts = Post.all

    render json: @posts
  end

  def my_posts
    @posts = current_user.posts
    render json: @posts
  end

  # GET /posts/1
  def show
    render json: @post
  end

  # POST /posts
  def create
    @post = current_user.posts.new(post_params)

    if @post.save
      render json: @post, status: :created
    else
      render json: @post.errors, status: :unprocessable_entity
    end
  end

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
    # Use callbacks to share common setup or constraints between actions.
    def set_post
      @post = Post.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def post_params
      params.require(:post).permit(:title, :content, :user_id)
    end

    # https://github.com/varvet/pundit#policies
    def authorize(post)
      @user = post.user
      raise "not allowed to perform this action" unless @user == current_user
    end
end
