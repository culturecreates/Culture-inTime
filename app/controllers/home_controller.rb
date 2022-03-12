class HomeController < ApplicationController

  # GET /
  def index
    @most_viewed = RDFGraph.spotlight(Spotlight.first)[1..5]
    @newly_added_spotlights = Spotlight.order(updated_at: :desc).limit(4)
  end

end