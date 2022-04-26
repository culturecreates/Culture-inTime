class BatchFederatedUpdateJob < ApplicationJob
  queue_as :default

  # Params: 0 -> uri, 1 -> graph_name, 2 -> type_uri, 3 -> sparql_endpoint
  def perform(*args)
    sparql = <<~SPARQL
    INSERT {
      graph <#{args[1]}> {
        <#{args[0]}> ?p ?o ; a <#{args[2]}>
      } 
    }
    WHERE { 
        SERVICE <#{args[3]}> {
        <#{args[0]}> ?p ?o . 
      }
    }
    SPARQL

    RDFGraph.update(sparql)
  end
end
