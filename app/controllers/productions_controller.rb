class ProductionsController < ApplicationController
  before_action :set_production, only: [ :edit, :update, :destroy]

  # GET /productions
  # GET /productions.json
  # Output: @productions list of Class Entity
  def index
    spotlight = Spotlight.find(1)
    @productions = RDFGraph.spotlight(spotlight)[1..5]
  end

  # GET /productions/show?uri=
  # Input: uri String
  # Output: 
  #   @graph Class RDFGraph to display as JSON-LD in footer 
  #   @production Class Entity
  #   @properties_with_labels SPARQL JSON response to iterate on additional properties to display
  def show
    # Load a local graph with first set of triples
    uri = params[:uri]
    @graph = RDFGraph.production(uri)

    cit = RDF::Vocabulary.new("http://culture-in-time.org/ontology/")
    query = RDF::Query.new({
      production: {
     #   RDF.type  => schema.Event,
        cit.title => :title,
      }
    }, **{})
    
    query << RDF::Query::Pattern.new(:production, cit.placeName, :placeName, optional: true)
    query << RDF::Query::Pattern.new(:production, cit.image, :image, optional: true)
    query << RDF::Query::Pattern.new(:production, cit.description, :description, optional: true)
    query << RDF::Query::Pattern.new(:production, cit.startDate, :startDate, optional: true)

    solution =  query.execute(@graph).first
    @production = Entity.new
    @production.load_solution(solution)

    # List properties with labels
    query = SPARQL.parse(<<~SPARQL)
    PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
    SELECT distinct ?label ?o ?p ?o_label
    WHERE { 
      ?s ?p ?o  .
      OPTIONAL { ?o rdfs:label ?o_label . } 
      OPTIONAL { ?p rdfs:label ?label_en .
        filter(lang(?label_en) = "en") }
      OPTIONAL { ?p rdfs:label ?label_none .
        filter(lang(?label_none) = "") }
      BIND (COALESCE(?label_en, ?label_none) as ?label)
      filter(Bound(?label))
      filter(?label != "label")
    } 
    order by ?label
    SPARQL

    @properties_with_labels = query.execute(@graph).to_json
 


    ############## Layers 
    # layers = DataSource.all.select {|d| d.layers.ids == [@production.data_source.id]}

    # puts "layers: #{layers}"
    # loader = LoadProductions.new
    # @details_list = []
    # layers.each do |layer|
    #   puts "Getting layer #{layer.id}"
    #   layer_output = loader.query_uri(layer, "<#{@production[:production_uri]}>")
    #   @details_list << layer_output
      
    #   if layer_output.to_s.include?("param_placeholder")
    #     another_layer = DataSource.all.select {|d| d.layers.ids == [layer.id]}
    #     another_output = loader.query_uri(another_layer.first, layer_output[0]["param_placeholder"]["value"])
    #     @details_list << another_output
    #   end

    # end

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
