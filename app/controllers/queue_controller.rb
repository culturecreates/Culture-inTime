class QueueController < ApplicationController
  require 'sidekiq/api'

  def index
    @queues = Sidekiq::Queue.all
    @current = Sidekiq::Queue.new.size 
    @stats = Sidekiq::Stats.new
    @history = Sidekiq::Stats::History.new(7)
  end

  def clear
    Sidekiq::Queue.new.clear
    redirect_to(index_queue_path)
  end
end
