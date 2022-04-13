class ProductionsController < ApplicationController
  before_action :set_production, only: [ :edit, :update, :destroy]

  # GET /productions
  # GET /productions.json
  # Output: @productions list of Class Entity
  def index
    @productions = Entity.spotlight(1)[1..5]
  end

  # GET /productions/show?uri=
  # Input: uri String
  # Output: 
  #   @production Class Entity with methodes graph and properties_with_labels
  def show
    @production = Entity.find(params[:uri])

  end

end
