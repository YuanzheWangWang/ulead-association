class TagsController < ApplicationController
  before_action :ensure_signed_in!, except: %i[index show]
  before_action :set_tag, except: %i[index new create]

  def index
    @tags = Tag.all.paginate page: params[:page]
  end

  def new
    @tag = Tag.new
  end

  def create
    @tag = if params[:query].present?
             Tag.new name: params[:query]
           else
             Tag.new tag_params
           end

    if @tag.save
      flash[:success] = "Created tag ##{@tag.name}."
      if params[:query].present?
        redirect_back fallback_location: @tag
      else
        redirect_to @tag
      end
    else
      flash[:danger] = 'Errors encountered when creating the tag.'
      render :new
    end
  end

  def show
    @articles = @tag.articles.ordered.viewable_by(this_user).paginate page: params[:page]
  end

  def edit; end

  def update
    if @tag.update tag_params
      flash[:success] = 'Updated the tag.'
      redirect_to @tag
    else
      flash[:error] = 'Failed to update the tag.'
      render :edit
    end
  end

  def destroy
    flash[:secondary] = "Deleted tag ##{@tag.destroy.name}."
    redirect_to tags_path
  end

  def add_article
    @article = Article.find params[:article_id]
    no_permission unless this_user.can_edit? @article

    if @tag.articles.include? @article
      flash[:warning] = "The article already has tag ##{@tag.name}."
    else
      @tag.articles << @article
      flash[:success] = "Added tag ##{@tag.name} to article \"#{@article.title}\"."
    end
    redirect_back fallback_location: edit_tags_path(@article)
  end

  def remove_article
    @article = Article.find params[:article_id]
    no_permission unless this_user.can_edit? @article

    if @tag.articles.include? @article
      @tag.articles.delete @article
      flash[:secondary] = "Removed tag ##{@tag.name} from article \"#{@article.title}\"."
    else
      flash[:warning] = "The article does not have tag ##{@tag.name}."
    end
    redirect_back fallback_location: edit_tags_path(@article)
  end

  private

  def tag_params
    params.require(:tag).permit(:name, :description)
  end

  def set_tag
    @tag = Tag.find params[:id]
  end
end
