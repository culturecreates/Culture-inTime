module JobsHelper 
  
  def convert_to_star(graph)
    sparql = SparqlLoader.load('convert_wikidata_to_rdf_star')
    sse = SPARQL.parse(sparql, update: true, rdfstar: true)
    graph.query(sse, rdfstar: true)
    graph
  end

end