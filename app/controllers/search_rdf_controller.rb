class SearchRdfController < ApplicationController
  def index

    @entities = RDFGraph.all
  end
end
