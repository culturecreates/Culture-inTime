class DataSource < ApplicationRecord
  has_and_belongs_to_many :spotlights
  
  has_and_belongs_to_many :layers,
    class_name: "DataSource",
    join_table: :chains, 
    foreign_key: :data_source_id, 
    association_foreign_key: :linked_data_source_id

   validates :name, presence: true

  # Method to load data source into a graph
  def load_rdf(test_drive = false)
    @response = RDFGraph.execute(sparql_new_or_updated_entities)
    if @response[:code] != 200
      self.errors.add(:base, "#{@response[:message]}")
      return false
    end

    data = @response[:message]

    if data.first.blank? 
      self.errors.add(:base, "No results.", message: "The SPARQL has not returned any results.")
      return false 
    end
    if !data.first.has_key?("uri")
      self.errors.add(:base, "Missing ?uri variable.", message: "Please use the variable ?uri in your SELECT to return a list of URIs.")
      return false 
    end
    @uris = data.pluck("uri").pluck("value")

    # This limit is set in the GraphDB respository as the "Limit query results"
    if @uris.count >= 100000
      self.errors.add(:base, "Exceeded limit of 100,000 URIs. Please break query into smaller groups.")
      return false 
    end

    # There are 2 methods to load data: 
    # 1. URI dereferencing. This can be used with Wikidata and Musicbrainz.
    # 2. SPARQL_describe which uses SPARQL Describe on a sparql endpoint. This is useful when the URIs are not dereferenceable.
    if self.fetch_method == "SPARQL_describe"
      if !test_drive
        #TODO: get endpoint from sparql SERVICE
        sparql_endpoint = 'http://db.artsdata.ca/repositories/artsdata'
        @uris.each do |uri|
          BatchFederatedUpdateJob.perform_later(uri, graph_name, self.type_uri, sparql_endpoint)
        end
      end
    else
      @sample_uri = @uris.first
      begin 
        @sample_graph = RDF::Graph.load(@sample_uri).to_jsonld
        puts "Sample graph loaded"
      rescue => exception
        puts "Exception getting sample uri: #{exception.inspect}"
      end
      return false unless @sample_graph

      if !test_drive
        # chunk in smaller arrays incase one fails in the queue
        # for a list of 100,000 URIs this will queue 200 jobs 
        @uris.each_slice(200) do |chunk|
          SetupContentNegotiationJob.perform_later(chunk, graph_name, self.type_uri)
        end
        self.loaded = Time.now
        self.save
      end
    end
    return true
  end

  def apply_upper_ontology
    BatchUpdateJob.perform_now(apply_upper_ontology_sparql)
  end

  def convert_to_rdf_star 
    BatchUpdateJob.perform_later(convert_wikidata_to_rdf_star_graph_sparql)
  end

  def fix_labels 
    BatchUpdateJob.perform_later(fix_wikidata_property_labels_sparql)
    BatchUpdateJob.perform_later(fix_wikidata_anotated_entity_labels_sparql)
  end

  # Dereference all objects of any type steming from the main entity class {self.type_uri}
  def load_secondary
    sparql = <<~SPARQL
      select distinct ?uri 
      where {
        graph <#{graph_name}> {
          ?s a <#{self.type_uri}> .
          ?s ?p ?uri  .
          ?uri a <http://wikiba.se/ontology#Item> .
        }
        MINUS {
          ?uri <http://www.wikidata.org/prop/direct/P31> ?sometype .
        }
        MINUS {
          ?uri <http://www.wikidata.org/prop/direct/P279> ?sometype .
        }
      }
    SPARQL

    @response = RDFGraph.execute(sparql)

    puts "######### #{@response}"
    if @response[:code] != 200
      puts "found error"
      self.errors.add(:base, "#{@response[:message]}")
      return false
    end

    data = @response[:message]

    @secondary_uris = []

    return true unless data.present?
    
    @secondary_uris = data.pluck("uri").pluck("value")
    
    # This limit is set in the GraphDB respository as the "Limit query results"
    if @secondary_uris.count >= 100000
      self.errors.add(:base, "Exceeded limit of 100,000 URIs. Please break query into smaller groups.")
      return false 
    end
  
    # chunk in smaller arrays incase one fails in the queue
    # for a list of 100,000 URIs this will queue 200 jobs 
    @secondary_uris.each_slice(200) do |chunk|
      SetupContentNegotiationJob.perform_later(chunk, graph_name)
      puts "Batch sent...."
    end
  
    puts "Returning true!"
    return true
  end

  # Dereference all objects of any type
  def load_tertiary
    sparql = <<~SPARQL
      select distinct ?uri
      where {
        graph <#{graph_name}> {
            ?s a <#{self.type_uri}> .
            ?s ?p ?uri_secondary .
            ?uri_secondary ?p_secondary ?uri .
            ?uri a <http://wikiba.se/ontology#Item> .
        } 
        MINUS {
            ?uri <http://www.wikidata.org/prop/direct/P31> ?some_instance_of_entity .
        } 
        MINUS {
            ?uri <http://www.wikidata.org/prop/direct/P279> ?some_subclass_of_entity .
        } 
      }
    SPARQL


    @response = RDFGraph.execute(sparql)

    if @response[:code] != 200
      puts "found error in tertiary load"
      self.errors.add(:base, "#{@response[:message]}")
      return false
    end

    data = @response[:message]

    @tertiary_uris = []

    return true unless data.present?
    
    @tertiary_uris = data.pluck("uri").pluck("value")
    
    # This limit is set in the GraphDB respository as the "Limit query results"
    if @tertiary_uris.count >= 100000
      self.errors.add(:base, "Exceeded limit of 100,000 tertiary URIs. Please break query into smaller groups.")
      return false 
    end
  
    # chunk in smaller arrays incase one fails in the queue
    # for a list of 100,000 URIs this will queue 200 jobs 
    @tertiary_uris.each_slice(200) do |chunk|
      SetupContentNegotiationJob.perform_later(chunk, graph_name)
      puts "Tertiary Batch sent...."
    end
  
    puts "Returning true for tertiary load!"
    return true
  end


  def sample_graph
    return @sample_graph
  end

  def uri_count
    return @uris.count
  end

  def secondary_uri_count
    return @secondary_uris.count
  end

  def tertiary_uri_count
    return @tertiary_uris.count
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
    SparqlLoader.load('data_source_index',[
      'graph_placeholder', graph_name,
      'entity_class_placeholder', self.type_uri,
      'ui_language', I18n.locale.to_s
    ])
  end

  def apply_upper_ontology_sparql
    SparqlLoader.load('apply_upper_ontology', [
      'graph_placeholder', graph_name,
      'type_uri_placeholder' , self.type_uri,
      '<languages_placeholder>', self.upper_languages.present? ? self.upper_languages.split(",").map {|l| "\"#{l}\"" }.join(" ") : "\"en\" \"fr\" \"de\"",
      '<title_prop_placeholder>', self.upper_title.present? ? self.upper_title : "schema:title" ,
      '<date_prop_placeholder>', self.upper_date.present? ? self.upper_date : "schema:startDate",
      '<description_prop_placeholder>', self.upper_description.present? ? self.upper_description : "schema:description",
      '<place_name_prop_placeholder>', self.upper_place.present? ? self.upper_place : "schema:location/schema:name",
      '<image_prop_placeholder>' , self.upper_image.present? ? self.upper_image : "schema:image"
    ])
  end

  def fix_wikidata_property_labels_sparql
    SparqlLoader.load('fix_wikidata_property_labels', [
      'graph_placeholder', graph_name
    ])
  end

  def convert_wikidata_to_rdf_star_graph_sparql
    SparqlLoader.load('convert_wikidata_to_rdf_star_graph', [
      'graph_placeholder', graph_name
    ])
  end

  

  def fix_wikidata_anotated_entity_labels_sparql
    SparqlLoader.load('fix_wikidata_anotated_entity_labels', [
      'graph_placeholder', graph_name
    ])
  end

  # remove entities that already exist and have not been modified since last loaded
  def sparql_minus_unchanged_entities 
    sparql = self.sparql
    sparql_parts = self.sparql.rpartition('}') # splits first occurance from right side
    sparql = sparql_parts[0] + "MINUS { ?uri a <#{self.type_uri}> . }" + sparql_parts[1] + sparql_parts[2]
    sparql
  end

  def sparql_with_cache_date
    if self.loaded
      self.sparql.gsub("CACHEDATE", "\"#{self.loaded.to_time.iso8601}\"^^<http://www.w3.org/2001/XMLSchema#dateTime>")
    else
      self.sparql.gsub("CACHEDATE", "\"#{Time.now.iso8601}\"^^<http://www.w3.org/2001/XMLSchema#dateTime>")
    end
  end

  # Modify the source's sparql to avoid reloaded existing entites
  def sparql_new_or_updated_entities
    if self.sparql.include?("CACHEDATE")
      # if using CACHEDATE then set CACHEDATE so the source can load only updated entites
      sparql_with_cache_date
    else
      # add a minus {} to not reload entities already loaded
      sparql_minus_unchanged_entities
    end
  end

end