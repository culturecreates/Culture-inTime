class HomeController < ApplicationController

  # GET /
  def index
    @most_viewed = Entity.spotlight(1)[1..5]
    @newly_added_spotlights = Spotlight.order(updated_at: :desc).limit(4)
  end

end