class SpotlightsController < ApplicationController
  before_action :set_spotlight, only: [:show, :edit, :update, :destroy]

  # GET /spotlights
  # GET /spotlights.json
  def index
    @spotlights = Spotlight.all.order(:title)
  end

  # GET /spotlights/1
  # GET /spotlights/1.json
  def show
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
    puts "Adding data sources...#{params[:spotlight][:data_sources]} "
    params[:spotlight][:data_sources].each do |k,v|
      puts "check #{DataSource.find(k).name}"
      @spotlight.data_sources << DataSource.find(k) if v == "1"
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
      params.require(:spotlight).permit(:title, :subtitle, :image, :description, :location, :start_date, :end_date, :query, :data_sources )
    end
end
