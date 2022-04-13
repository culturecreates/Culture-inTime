
class Entity
  attr_accessor :title, :description, :date_of_first_performance, :location_label, :main_image, :entity_uri

  def initialize(**h) 
    @title = h[:title]
    @description = h[:description]
    @date_of_first_performance = h[:date]
    @location_label = h[:place]
    @main_image = h[:image]
    @entity_uri = h[:entity_uri]
  end

  # Class method to find all entities given a DataSource id
  def self.data_source(data_source_id)
    data_source = DataSource.find(data_source_id)
    results = RDFGraph.execute(data_source.generate_sparql)
    load_entities(results[:message])
  end

  # Class method to find all entities given a Spotlight id
  def self.spotlight(spotlight_id)
    spotlight = Spotlight.find(spotlight_id)
    results = RDFGraph.execute(spotlight.generate_sparql)
    load_entities(results[:message])
  end

  def self.count
    @count || 0
  end


  # Class method that returns a list of entities of Class Entity
  def self.load_entities(sparql_results)
    @count = sparql_results.count
    entities = []
    sparql_results.first(20).each do |e|
      title = e["title"]["value"] || ""
      description = e.dig("description","value") || ""
      startDate = e.dig("startDate","value") || ""
      place = e.dig("place","value") || ""
      image = e.dig("image","value") || ""
      entity_uri = e.dig("uri","value") || ""
      entities << Entity.new(title: title, description: description, startDate: startDate,  place: place, image: image, entity_uri: entity_uri)
    end
    entities
  end


  def method_missing(m,*args,&block)
    if m.to_s == 'main_image'
      ""
    else
      "missing"
    end 
  end

  def graph
    @graph ||= load_graph
  end

  # Loads details of a URI in graph format
  # Input: Production URI string
  # Output: RDF Graph
  def load_graph
    graph = RDF::Graph.new
    sparql = <<~SPARQL
    PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#> 
    CONSTRUCT {
      <#{@entity_uri}> ?p ?o .
      ?o rdfs:label ?o_label . 
      ?p rdfs:label ?label .
      } 
    WHERE { 
      <#{@entity_uri}> ?p ?o . 
      OPTIONAL { ?p rdfs:label ?label . }
      OPTIONAL { ?o rdfs:label ?o_label . }
    }
    SPARQL
    
    response = RDFGraph.construct(sparql)
    if response[:code] == 200
      graph << JSON::LD::API.toRdf(response[:message])
    end
    graph
  end


  def self.find(entity_uri)
    entity = Entity.new(entity_uri: entity_uri)
    graph = entity.graph

    # load upper ontology into entity
    solution =  entity.upper_ontology_query.execute(graph).first

    entity.title = solution.title if solution.bound?(:title)
    entity.description = solution.description.value if solution.bound?(:description)
    entity.date_of_first_performance = solution.startDate.value if solution.bound?(:startDate)
    entity.location_label = solution.placeName if  solution.bound?(:placeName)
    entity.main_image = solution.image if  solution.bound?(:image)
    entity
  end

  def properties_with_labels
    query = SPARQL.parse(<<~SPARQL)
    PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
    SELECT distinct ?label ?o ?p ?o_label
    WHERE { 
      ?s ?p ?o  .
      OPTIONAL { ?o rdfs:label ?o_label . } 
      OPTIONAL { ?p rdfs:label ?label_en .
        filter(lang(?label_en) = "en") }
      OPTIONAL { ?p rdfs:label ?label_none .
        filter(lang(?label_none) = "") }
      BIND (COALESCE(?label_en, ?label_none) as ?label)
      filter(Bound(?label))
      filter(?label != "label")
      filter(?o != "")
    } 
    order by ?label
    SPARQL

    @properties_with_labels ||= query.execute(graph).to_json
    
  end

  def upper_ontology_query
    cit = RDF::Vocabulary.new("http://culture-in-time.org/ontology/")
    query = RDF::Query.new({
      production: {
        cit.title => :title,
      }
    }, **{})
  
    query << RDF::Query::Pattern.new(:production, cit.placeName, :placeName, optional: true)
    query << RDF::Query::Pattern.new(:production, cit.image, :image, optional: true)
    query << RDF::Query::Pattern.new(:production, cit.description, :description, optional: true)
    query << RDF::Query::Pattern.new(:production, cit.startDate, :startDate, optional: true)
    query
  end
end