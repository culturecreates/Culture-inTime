class ApplicationController < ActionController::Base
  # around_action :switch_locale

  # def switch_locale(&action)
  #   locale = params[:locale] || I18n.default_locale
  #   I18n.with_locale(locale, &action)
  # end

 
rescue_from ActiveRecord::RecordNotFound, with: :not_found_resp

before_action :set_locale

def not_found_resp  
  redirect_to spotlights_url, notice: 'Please create your first spotlight.'
end

 
def set_locale
  I18n.locale = params[:locale] || I18n.default_locale
end

  def default_url_options
    { locale: I18n.locale }
  end

end
