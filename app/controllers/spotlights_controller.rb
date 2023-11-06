class SpotlightsController < ApplicationController
  before_action :set_spotlight, only: [:show, :edit, :update, :destroy, :stats_prop, :stats_qual, :stats_ref, :stats_inverse_prop, :download, :update_layout]

  # GET /spotlights
  # GET /spotlights.json
  def index
    @spotlights = Spotlight.all.order(:title)
  end
  
  # GET /spotlights/1
  # GET /spotlights/1.json
  def show
    @layout = Layout.new(@spotlight.layout)
    @data_sources = DataSource.all
  end

  # PATCH /spotlights/1/update_layout
  def update_layout
    # save layout turtle to graphdb and popup success.
    turtle = @spotlight.layout
    layout_id = params[:id]
    graph_name = helpers.generate_layout_graph_name(layout_id)
    RDFGraph.drop(graph_name)
    RDFGraph.persist(turtle, graph_name)
    redirect_to @spotlight, notice: 'Spotlight layout was successfully updated.'
  end

  # GET /spotlights/1/download.json&refresh=&style=
  def download
    @spotlight.dump = nil if params[:refresh]

    if params[:style] != "wikidata"
      if @spotlight.dump && @spotlight.dump != "loading"
        output = @spotlight.dump
      else
        if @spotlight.dump != "loading"
          DumpSpotlightJob.perform_later(@spotlight.id)
          @spotlight.dump = "loading"
          @spotlight.save
        end
        notice = "Compiling spotlight data... Try again in a minute!"
      end
    else
      # todo: move to background job
      if @spotlight.frame.present?
        graph = @spotlight.compile_dump_graph
        frame_json = JSON.parse(@spotlight.frame)
        output = JSON::LD::API.frame( JSON.parse(graph.to_jsonld), frame_json).to_json
      else
        notice = 'Could not export. Please check your JSON-LD Frame in the API screen.'
      end
    end
    if output 
      send_data  output, :disposition => 'attachment', :filename=>"#{@spotlight.title}.jsonld"
    else
      redirect_to @spotlight, notice: notice
    end
  end

  # GET /spotlights/1/stats_prop
  def stats_prop
    results = RDFGraph.execute(@spotlight.generate_sparql_stats_prop)
    @properties = results[:message]
    render "stats"
  end

  # GET /spotlights/1/stats_qual
  def stats_qual
    results = RDFGraph.execute(@spotlight.generate_sparql_stats_qual)
    @properties = results[:message]
    render "stats"
  end

  # GET /spotlights/1/stats_ref
  def stats_ref
    results = RDFGraph.execute(@spotlight.generate_sparql_stats_ref)
    @properties = results[:message]
    render "stats"
  end

  # GET /spotlights/1/stats_inverse_prop
  def stats_inverse_prop
    results = RDFGraph.execute(@spotlight.generate_sparql_stats_inverse_prop)
    @direction = "Reverse"
    @properties = results[:message]
    render "stats"
  end

  # GET /spotlights/new
  def new
    @spotlight = Spotlight.new
    @data_sources = DataSource.all
  end

  # GET /spotlights/1/edit
  def edit
    @data_sources = DataSource.all
  end

  # POST /spotlights
  # POST /spotlights.json
  def create
    @data_sources = DataSource.all
    
    @spotlight = Spotlight.new(spotlight_params)
   
    if params[:spotlight][:data_sources]
      params[:spotlight][:data_sources].each do |k,v|
        # puts "check #{DataSource.find(k).name}"
        @spotlight.data_sources << DataSource.find(k) if v == "1"
      end
    end

    respond_to do |format|
      if @spotlight.save
        format.html { redirect_to @spotlight, notice: 'Spotlight was successfully created.' }
        format.json { render :show, status: :created, location: @spotlight }
      else
        format.html { render :new }
        format.json { render json: @spotlight.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /spotlights/1
  # PATCH/PUT /spotlights/1.json
  def update
    respond_to do |format|
      if @spotlight.update(spotlight_params)
        format.html { redirect_to @spotlight, notice: 'Spotlight was successfully updated.' }
        format.json { render :show, status: :ok, location: @spotlight }
      else
        format.html { render :edit }
        format.json { render json: @spotlight.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /spotlights/1
  # DELETE /spotlights/1.json
  def destroy
    @spotlight.destroy
    respond_to do |format|
      format.html { redirect_to spotlights_url, notice: 'Spotlight was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_spotlight
      @spotlight = Spotlight.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def spotlight_params
      params.require(:spotlight).permit(:layout, :sparql, :title, :subtitle, :image, :description, :location, :start_date, :end_date, :query, :language, :frame, data_source_ids: [])
    end
end
