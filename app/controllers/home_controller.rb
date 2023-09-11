class HomeController < ApplicationController

  # GET /
  def index
    @most_viewed = []
    @newly_added_spotlights = Spotlight.order(updated_at: :desc).limit(4)
  end

end