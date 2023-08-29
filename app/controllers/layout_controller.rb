class LayoutController < ApplicationController

  def add_field
    @spotlight = Spotlight.find(params[:spotlight])
    @layout = Layout.new(@spotlight.layout)
    if @layout.add_field(params[:uri], params[:name], params[:direction])
      # puts "saving fields:#{@layout.turtle}"
      @spotlight.layout = @layout.turtle
      @spotlight.save
    end
    render "refresh_field"
  end

  def delete_field
    @spotlight = Spotlight.find(params[:spotlight])
    @layout = Layout.new(@spotlight.layout)
    if @layout.delete_field(params[:uri])
      @spotlight.layout = @layout.turtle
      @spotlight.save
    end
    render "refresh_field"
  end

  def move_up
    @spotlight = Spotlight.find(params[:spotlight])
    @layout = Layout.new(@spotlight.layout)
    @layout.move_up(params[:uri])
    @spotlight.layout = @layout.turtle
    @spotlight.save
    render "refresh_field"
  end

  def move_down
    @spotlight = Spotlight.find(params[:spotlight])
    @layout = Layout.new(@spotlight.layout)
    @layout.move_down(params[:uri])
    @spotlight.layout = @layout.turtle
    @spotlight.save
    render "refresh_field"
  end
end
