class SearchRdfController < ApplicationController
  def index

    @entities = RDFGraph.all
  end

  def spotlight 
    spotlight = Spotlight.find(params[:spotlight])
    @entities = RDFGraph.spotlight(spotlight)
    @count = RDFGraph.count
    render "index"
  end
end
