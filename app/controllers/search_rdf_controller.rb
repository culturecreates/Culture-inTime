class SearchRdfController < ApplicationController
  def index
    @entities = Entity.spotlight(1)
  end

  def spotlight 
    @entities = Entity.spotlight(params[:spotlight])
    @count = Entity.count
    render "index"
  end

  def data_source
    @entities = Entity.data_source(params[:data_source])
    @count = Entity.count  # TODO: fix count i.e. Entity.data_source_count(params[:data_source])
    render "index"
  end
end