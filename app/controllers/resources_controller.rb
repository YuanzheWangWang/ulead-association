class ResourcesController < ApplicationController
  before_action :ensure_signed_in!
  before_action :ensure_developer!, except: :upload

  def index
    @resources = Dir.entries(Rails.root.join('public', 'rc')).select { |r| /[A-Fa-f0-9]{64}/ =~ r }
  end

  def upload
    filepath = Rails.root.join('storage', SecureRandom.uuid.to_s)
    File.open(filepath, 'wb') do |f|
      f.write params[:file].read
    end

    digest = Digest::SHA256.file(filepath).hexdigest
    realpath = Rails.root.join 'public', 'rc', digest
    if File.file? realpath
      File.delete filepath
    else
      File.rename filepath, realpath
    end

    render plain: "/rc/#{digest}"
  end

  def destroy
    path = Rails.root.join 'public', 'rc', params[:digest]
    if File.file? path
      File.delete path
      flash[:secondary] = "Deleted resource #{params[:digest]}."
    else
      flash[:warning] = "No such resource #{params[:digest]}."
    end
    redirect_to resources_path
  end
end