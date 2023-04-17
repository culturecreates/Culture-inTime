class BatchContentNegotiationJob < ApplicationJob
  queue_as :default

  def perform(*args)
    uri = args[0]
    graph_name = args[1]
    type_uri = args[2] || nil
    
    graph = RDF::Graph.load(uri)
    if type_uri
      graph << [RDF::URI(uri), RDF.type, RDF::URI(type_uri)]
    end
    RDFGraph.persist(graph.to_turtle, graph_name)
  end
end
