class DataSourcesController < ApplicationController
  before_action :set_data_source, only: [:show, :apply_upper_ontology,  :load_rdf, :edit, :update, :destroy]

  # GET /data_sources
  # GET /data_sources.json
  def index
    @data_sources = DataSource.all.order(:name)
  end

  # GET /data_sources/1
  # GET /data_sources/1.json
  def show
  end

  # GET /data_sources/1/load
  def apply_upper_ontology
    flash.now[:notice] = "Upper ontology applied!"
    render 'show'
  end

  # GET /data_sources/1/load_rdf
  def load_rdf
    if @data_source.type_uri.blank?
      flash.now[:notice] = "Need a type." 
      render 'show'
    else
      loader = LoadRDF.new
      loader.source(@data_source)
      @sample_graph = loader.sample
      @sample_uri = loader.sample_uri
      if loader.error?
        flash.now[:notice] = "Ran into a problem. #{loader.errors}"
        render 'show', notice: "Ran into a problem. #{loader.errors}"
      else
        flash.now[:notice] = "#{loader.count} URIs returned by SPARQL #{loader.cache_errors}"
      end
      render 'show'
    end
  end


  # GET /data_sources/new
  def new
    @data_source = DataSource.new
    @data_sources = DataSource.all
  end

  # GET /data_sources/1/edit
  def edit
    @data_sources = DataSource.all
  end

  # POST /data_sources
  # POST /data_sources.json
  def create
    @data_sources = DataSource.all
    @data_source = DataSource.new(data_source_params)

    puts "Adding data sources...#{params[:data_source][:data_sources]} "
    params[:data_source][:data_sources].each do |k,v|
    @data_source.layers << DataSource.find(k) if v == "1"
  end

    respond_to do |format|
      if @data_source.save
        format.html { redirect_to @data_source, notice: 'Data source was successfully created.' }
        format.json { render :show, status: :created, location: @data_source }
      else
        format.html { render :new }
        format.json { render json: @data_source.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /data_sources/1
  # PATCH/PUT /data_sources/1.json
  def update
    respond_to do |format|
      if @data_source.update(data_source_params)
        format.html { redirect_to @data_source, notice: 'Data source was successfully updated.' }
        format.json { render :show, status: :ok, location: @data_source }
      else
        format.html { render :edit }
        format.json { render json: @data_source.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /data_sources/1
  # DELETE /data_sources/1.json
  def destroy
    @data_source.destroy
    respond_to do |format|
      format.html { redirect_to data_sources_url, notice: 'Data source was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_data_source
    @data_source = DataSource.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def data_source_params
    params.require(:data_source).permit(:upper_prefix, :upper_title, :upper_description, :upper_date, :upper_image, :upper_place, :upper_country, :upper_languages, :type_uri, :name, :sparql, :email, :loaded, :data_sources)
  end
end
