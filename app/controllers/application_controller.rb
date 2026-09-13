class ApplicationController < ActionController::Base
  before_action :authenticate_user!, unless: :devise_controller?
  layout :layout_by_resource

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  private

  # Devise's own pages (sign in, sign up, password reset) have no signed-in user yet,
  # so they can't render the authenticated shell's sidebar (which reads current_user).
  def layout_by_resource
    devise_controller? ? "devise" : "application"
  end
end
