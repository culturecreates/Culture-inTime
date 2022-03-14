class RDFGraph
  
  def self.graph
    @graph ||= RDF::Graph.new
    # graph ||= RDF::Graph.load('config/initializers/artsdata-dump.nt', format: :nquads)
  end

  # Input: Production URI string
  # Output: RDF Graph
  def self.production(uri)
    graph = RDF::Graph.new
    sparql = <<~SPARQL
    PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#> 
    CONSTRUCT {
      <#{uri}> ?p ?o .
      ?o rdfs:label ?o_label . 
      ?p rdfs:label ?label .
      } 
    WHERE { 
      <#{uri}> ?p ?o . 
      OPTIONAL { ?p rdfs:label ?label . }
      OPTIONAL { ?o rdfs:label ?o_label . }
    }
    SPARQL
    
    response = artsdata_client.execute_construct_sparql(sparql)
    if response[:code] == 200
      graph << JSON::LD::API.toRdf(response[:message])
    end
    #graph << [RDF::URI(uri), RDF.type, RDF::URI("http://schema.org/Event")]
    #graph << [RDF::URI(uri), RDF::URI("http://schema.org/name"), RDF::Literal("Test Name")]
    graph
  end

  # Input: ActiveRecord DataSource
  # Output: response hash {code: , message: }
  def self.upper_ontology(data_source)
    artsdata_client.execute_update_sparql(generate_upper_ontology_sparql(data_source))
  end

  # Input: ActiveRecord Spotlight
  # Output: entities -> list of Entity Classes
  def self.spotlight(spotlight)
    entities = []

    results =  artsdata_client.execute_sparql(generate_query_sparql(spotlight))

    results[:message].each do |e|
      
      title = e["title"]["value"] || ""
      description = e.dig("description","value") || ""
      startDate = e.dig("startDate","value") || ""
      place = e.dig("place","value") || ""
      image = e.dig("image","value") || ""
      entity_uri = e.dig("uri","value") || ""
      entities << Entity.new(title, description, startDate,  place, image, entity_uri)
    end
    entities
  end

  def self.persist(id)
    # artsdata_client.drop_graph(uri(id))
    artsdata_client.upload_turtle(graph.dump(:turtle), uri(id))
  end

  ################
  # Private
  #################

  def self.uri(id)
    "http://culture-in-time.com/graph/#{id}"
  end



  ##################
  #  SPARQL Templates
  ####################

  def self.generate_upper_ontology_sparql(data_source)
    SparqlLoader.load('apply_upper_ontology', [
      'graph_placeholder', uri(data_source.id),
      'type_uri_placeholder' , data_source.type_uri,
      '<languages_placeholder>', data_source.upper_languages.split(",").map {|l| "\"#{l}\"" }.join(" "),
      '<title_prop_placeholder>', data_source.upper_title,
      '<date_prop_placeholder>', data_source.upper_date,
      '<description_prop_placeholder>', data_source.upper_description,
      '<place_name_prop_placeholder>', data_source.upper_place,
      '<place_name_country_prop_placeholder>', data_source.upper_country,
      '<image_prop_placeholder>' , data_source.upper_image
    ])
    
  end

  def self.generate_query_sparql(spotlight)
    SparqlLoader.load('spotlight_productions',[
      '<spotlight_query_placeholder> a "triple"', spotlight.sparql
    ])
  end


  def self.artsdata_client
    @artsdata_client ||= ArtsdataApi::V1::Client.new(oauth_token: "YXJ0c2RhdGEtYXBpOlN5amNpeC16b3Z3ZXMtN3ZvYm1p")
  end
end


