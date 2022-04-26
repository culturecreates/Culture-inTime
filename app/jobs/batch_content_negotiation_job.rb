class BatchContentNegotiationJob < ApplicationJob
  queue_as :default

  def perform(*args)
    graph = RDF::Graph.load(args[0])
    graph << [RDF::URI(args[0]), RDF.type, RDF::URI(args[2])]
    RDFGraph.persist(graph.to_turtle, args[1])
  end
end
