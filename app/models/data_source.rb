class DataSource < ApplicationRecord
  has_many :productions, dependent: :destroy

  has_and_belongs_to_many :spotlights
  
  has_and_belongs_to_many :layers,
    class_name: "DataSource",
    join_table: :chains, 
    foreign_key: :data_source_id, 
    association_foreign_key: :linked_data_source_id


  # Method to drop and load data source into a graph
  def load_rdf
    @response = RDFGraph.execute(self.sparql)
    return false unless @response[:code] == 200

    @uris = @response[:message].pluck("uri").pluck("value")
    RDFGraph.drop(graph_name)
    if self.fetch_method == "SPARQL_describe"
      #TODO: get endpoint from sparql SERVICE
      sparql_endpoint = 'http://db.artsdata.ca/repositories/artsdata'
      @uris.each do |uri|
        BatchUpdateJob.set(queue: "graph-#{self.id}").perform_later(uri, graph_name, self.type_uri, sparql_endpoint)
      end
    else
      @sample_uri = @uris.first
      begin 
        @sample_graph = RDF::Graph.load(@sample_uri).to_jsonld
        puts "Sample graph: #{@sample_graph.inspect}"
      rescue => exception
        puts "Exception getting sample uri: #{exception.inspect}"
      end
      return false unless @sample_graph

      @uris.each do |uri|
        BatchContentNegotiationJob.perform_later(uri, graph_name, self.type_uri)
      end
      self.loaded = Time.now
      self.save

    end

    return true
  end

  def apply_upper_ontology
    RDFGraph.update(generate_upper_ontology_sparql)
  end

  def sample_graph
    return @sample_graph
  end

  def uri_count
    return @uris.count
  end

  def sample_uri 
    return  @sample_uri
  end

  def graph_name
    "http://culture-in-time.com/graph/#{self.id}"
  end

  # used by search_rdf 
  # SPARQL to load upper ontology of all entities in graph_name of type type_uri
  def generate_sparql
    SparqlLoader.load('data_source',[
      'graph_placeholder', graph_name,
      'entity_class_placeholder', self.type_uri
    ])
  end

  def generate_upper_ontology_sparql
    SparqlLoader.load('apply_upper_ontology', [
      'graph_placeholder', graph_name,
      'type_uri_placeholder' , self.type_uri,
      '<languages_placeholder>', self.upper_languages.split(",").map {|l| "\"#{l}\"" }.join(" "),
      '<title_prop_placeholder>', self.upper_title,
      '<date_prop_placeholder>', self.upper_date,
      '<description_prop_placeholder>', self.upper_description,
      '<place_name_prop_placeholder>', self.upper_place,
      '<place_name_country_prop_placeholder>', self.upper_country,
      '<image_prop_placeholder>' , self.upper_image
    ])
  end

end