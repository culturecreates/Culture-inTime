class BatchUpdateJob < ApplicationJob
  queue_as :default

  # Params: 0 -> sparql
  def perform(*args)
    RDFGraph.update(args[0])
  end
end
