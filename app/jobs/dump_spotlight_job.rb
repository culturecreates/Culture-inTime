class BatchUpdateJob < ApplicationJob
  queue_as :default

  # Params: 0 -> sparql
  def perform(*args)
    @spotlight = Spotlight.find(args[0])
    graph  = @spotlight.compile_dump_graph
    output = graph.dump(:jsonld, validate: false)
    @spotlight.dump = output
    @spotlight.save
  end
end