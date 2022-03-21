class RDFGraph

  def self.execute(sparql)
    artsdata_client.execute_sparql(sparql)
  end


  def self.update(sparql)
    artsdata_client.execute_update_sparql(sparql)
  end

  ## Returns JSON-LD from a construct sparql
  def self.construct(sparql)
    artsdata_client.execute_construct_sparql(sparql)
  end


  ############## OLD ##
  
  def self.graph
    @graph ||= RDF::Graph.new
    # graph ||= RDF::Graph.load('config/initializers/artsdata-dump.nt', format: :nquads)
  end

  def self.drop
    @graph = RDF::Graph.new
  end

  def self.count
    @count ||= 0
    # graph ||= RDF::Graph.load('config/initializers/artsdata-dump.nt', format: :nquads)
  end

  # Returns details of a URI in graph format
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
    results =  artsdata_client.execute_sparql(generate_query_sparql(spotlight))
    load_entities(results[:message])
    
  end

  # Input: ActiveRecord DataSource
  # Output: entites -> list of Entity Classes
  def self.data_source(data_source)
    results =  artsdata_client.execute_sparql(generate_data_source_sparql(data_source))
    load_entities(results[:message])
  end


  def self.persist(id)
    # artsdata_client.drop_graph(uri(id))
    artsdata_client.upload_turtle(graph.dump(:turtle), uri(id))
  end

  ################
  # Private
  #################

  # def self.uri(id)
  #   "http://culture-in-time.com/graph/#{id}"
  # end

  # def self.load_entities(sparql_results)
  #   @count = sparql_results.count
  #   entities = []
  #   sparql_results.first(20).each do |e|
  #     title = e["title"]["value"] || ""
  #     description = e.dig("description","value") || ""
  #     startDate = e.dig("startDate","value") || ""
  #     place = e.dig("place","value") || ""
  #     image = e.dig("image","value") || ""
  #     entity_uri = e.dig("uri","value") || ""
  #     entities << Entity.new(title, description, startDate,  place, image, entity_uri)
  #   end
  #   entities
  # end


  ##################
  #  SPARQL Templates
  ####################

  # old
  # def self.generate_upper_ontology_sparql(data_source)
  #   SparqlLoader.load('apply_upper_ontology', [
  #     'graph_placeholder', uri(data_source.id),
  #     'type_uri_placeholder' , data_source.type_uri,
  #     '<languages_placeholder>', data_source.upper_languages.split(",").map {|l| "\"#{l}\"" }.join(" "),
  #     '<title_prop_placeholder>', data_source.upper_title,
  #     '<date_prop_placeholder>', data_source.upper_date,
  #     '<description_prop_placeholder>', data_source.upper_description,
  #     '<place_name_prop_placeholder>', data_source.upper_place,
  #     '<place_name_country_prop_placeholder>', data_source.upper_country,
  #     '<image_prop_placeholder>' , data_source.upper_image
  #   ])
    
  # end

  # old
  # def self.generate_query_sparql(spotlight)
  #   SparqlLoader.load('spotlight_productions',[
  #     '<spotlight_query_placeholder> a "triple"', spotlight.sparql
  #   ])
  # end

  # old
  # def self.generate_data_source_sparql(data_source)
  #   SparqlLoader.load('data_source',[
  #     'graph_placeholder', uri(data_source.id),
  #     'entity_class_placeholder', data_source.type_uri
  #   ])
  # end


  def self.artsdata_client
    @artsdata_client ||= ArtsdataApi::V1::Client.new(oauth_token: Rails.application.credentials.dig(:graphdb, :oauth_token))
  end
end


