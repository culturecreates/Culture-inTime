class QueueController < ApplicationController
  require 'sidekiq/api'

  def index
    @current = Sidekiq::Queue.new.size 
    @stats = Sidekiq::Stats.new
    @history = Sidekiq::Stats::History.new(7)
  end

  def clear
    Sidekiq::Queue.new.clear
    redirect_to(index_queue_path)
  end

  def check_jobs
    puts "Checking job count..."
    # @current = if Rails.env.production?
    #   Sidekiq::Queue.new.size
    # else
    #   0
    # end
  end
end
