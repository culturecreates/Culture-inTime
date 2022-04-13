
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

  # not sure about this
  def load_solution(solution)
    if solution
      @title = solution.title if solution.bound?(:title)
      @description = solution.description.value if solution.bound?(:description)
      @date_of_first_performance = solution.startDate.value if solution.bound?(:startDate)
      @location_label = solution.placeName if  solution.bound?(:placeName)
      @main_image = solution.image if  solution.bound?(:image)
      @entity_uri = solution.production.value
    end
  end

  def method_missing(m,*args,&block)
    if m.to_s == 'main_image'
      ""
    else
      "missing"
    end 
  end

   # Returns details of a URI in graph format
  # Input: Production URI string
  # Output: RDF Graph
  def graph
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
    #graph << [RDF::URI(uri), RDF.type, RDF::URI("http://schema.org/Event")]
    #graph << [RDF::URI(uri), RDF::URI("http://schema.org/name"), RDF::Literal("Test Name")]
    graph
  end

end