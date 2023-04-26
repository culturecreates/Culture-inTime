class BatchContentNegotiationJob < ApplicationJob
  queue_as :default

  def perform(*args)
    uri = args[0]
    graph_name = args[1]
    type_uri = args[2] || nil
    
    # puts uri
    graph = RDF::Graph.load(uri, rdfstar: true)

    # Next unless schema:dateModified > last cached
    
    # Delete triples in triple store - only ?s ?p ?o and <<?s ?p ?o>> ?a ?b

    # Convert graph to rdf star

    ####################################
    # Graphdb LIMITATION : Need Graph DB to accept Turle annotations
    # Use this once supported, to convert individual entities to rdf star 
    # instead of waiting to convert all entities at the end
    ####################################
    # graph = ApplicationController.helpers.convert_to_star(graph)

    if type_uri
      graph << [RDF::URI(uri), RDF.type, RDF::URI(type_uri)]
      # BatchUpdateJob.perform_later(apply_upper_ontology_sparql)
    end

    RDFGraph.persist(graph.dump(:ttl, validate: false), graph_name)


  end
end
