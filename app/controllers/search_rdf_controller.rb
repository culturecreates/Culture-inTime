class SearchRdfController < ApplicationController
  def index
    @spotlight = params[:spotlight]
    @entities = if @spotlight
                  Entity.spotlight(@spotlight)
                elsif params[:data_source]
                  Entity.data_source(params[:data_source]) 
                else
                  Entity.spotlight(1)
                end
    @count = @entities.count
    @entities = @entities.paginate(page: params[:page], limit:params[:limit] )
  end

  def spotlight 
    @spotlight = params[:spotlight]
    @entities = Entity.spotlight(@spotlight).paginate(page: params[:page], limit:params[:limit])
    @count = Entity.count
    render "index"
  end

  def data_source
    @entities = Entity.data_source(params[:data_source]).paginate(page: params[:page])
    @count = Entity.count  # TODO: fix count i.e. Entity.data_source_count(params[:data_source])
    render "index"
  end
end