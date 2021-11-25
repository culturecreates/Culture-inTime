class ProductionsController < ApplicationController
  before_action :set_production, only: [:show, :edit, :update, :destroy]

  # GET /productions
  # GET /productions.json
  def index
    @productions = Production.order(updated_at: :desc).limit(5)
  end

  # GET /productions/1
  # GET /productions/1.json
  def show
    # get list of layers chained to this production
    # TODO: make loading layers recursive
    # TODO: make generic ?somevar --> SOMEVAR_PLACEHOLDER for any variable. (this is really cool. 
    #       Looks into the SPARQL to find the placeholders and pulls in the corresponding variables from the parent sparql.
    # TODO: join all ?param_placeholder strings. This can create a list of URIs or even a list of from <> from <> to load multiple musicbrains IDs
    # TODO: using https://www.deezer.com/[artist/1558] from Wikidata and a sparql html template, construct an <iframe title="deezer-widget" src="https://widget.deezer.com/widget/dark/[artist/1558]/top_tracks" width="100%" height="300" frameborder="0" allowtransparency="true" allow="encrypted-media; clipboard-write"></iframe>


    puts "looking for production id #{@production.data_source.id}"
    layers = DataSource.all.select {|d| d.layers.ids == [@production.data_source.id]}

    puts "layers: #{layers}"
    loader = LoadProductions.new
    @details_list = []
    layers.each do |layer|
      puts "Getting layer #{layer.id}"
      layer_output = loader.query_uri(layer, "<#{@production[:production_uri]}>")
      @details_list << layer_output
      
      if layer_output.to_s.include?("param_placeholder")
        another_layer = DataSource.all.select {|d| d.layers.ids == [layer.id]}
        another_output = loader.query_uri(another_layer.first, layer_output[0]["param_placeholder"]["value"])
        @details_list << another_output
      end

    end

  end

  # GET /productions/new
  def new
    @production = Production.new
  end

  # GET /productions/1/edit
  def edit
  end

  # POST /productions
  # POST /productions.json
  def create
    @production = Production.new(production_params)

    respond_to do |format|
      if @production.save
        format.html { redirect_to @production, notice: 'Production was successfully created.' }
        format.json { render :show, status: :created, location: @production }
      else
        format.html { render :new }
        format.json { render json: @production.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /productions/1
  # PATCH/PUT /productions/1.json
  def update
    respond_to do |format|
      if @production.update(production_params)
        format.html { redirect_to @production, notice: 'Production was successfully updated.' }
        format.json { render :show, status: :ok, location: @production }
      else
        format.html { render :edit }
        format.json { render json: @production.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /productions/1
  # DELETE /productions/1.json
  def destroy
    @production.destroy
    respond_to do |format|
      format.html { redirect_to productions_url, notice: 'Production was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_production
      @production = Production.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def production_params
      params.require(:production).permit(:data_source_id, :label, :location_label, :location_uri, :date_of_first_performance, :production_company_uri, :production_company_label, :description, :main_image)
    end
end
