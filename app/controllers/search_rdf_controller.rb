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

  def data_source
    data_source = DataSource.find(params[:data_source])
    @entities = RDFGraph.data_source(data_source)
    @count = RDFGraph.count
    render "index"
  end
end