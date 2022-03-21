class BatchUpdateJob < ApplicationJob
  queue_as :default

  def perform(*args)
    RDFGraph.update(args[0])
  end
end
