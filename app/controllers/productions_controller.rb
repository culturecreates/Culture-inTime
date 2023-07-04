class ProductionsController < ApplicationController
 # before_action :set_production, only: [ :edit, :update, :destroy]

  # GET /productions
  # GET /productions.json
  # Output: @productions list of Class Entity
  def index
    @productions = Entity.spotlight(1)[1..5]
  end

  # GET /productions/show?uri=
  # Input: uri String
  # Output: 
  #   @production Class Entity with methods graph and properties_with_labels
  def show
    entity = Entity.new(entity_uri: params[:uri])
    entity.layout_id = params[:layout]
    entity.graph
    @production = entity
  end

  # GET /productions/derived?uri=
  # Graph of URI in object position
  def derived 
    @production = Entity.derived(params[:uri])
    render 'show'
  end

   # GET /productions/wikidata?uri=
  # Graph of wikidata statement nodes instead of RDF Star
  def wikidata 
    @production = Entity.wikidata(params[:uri], params[:layout])
    render 'show'
  end

end
