
class Entity
  attr_accessor :title, :description, :date_of_first_performance, :location_label, :main_image, :entity_uri, :layout_id

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


  # Class method that returns an index list of entities
  def self.load_entities(sparql_results)
    @count = sparql_results.count
    
    @sparql_results = sparql_results
    self
  end

  def self.paginate(**params)
    entities = []
    @page = params[:page] ||= 1
    start_offset = 20*(@page.to_i - 1)
    end_offset = 20*(@page.to_i) - 1
    @sparql_results[start_offset..end_offset].each do |e|
      title = e.dig("title_lang","value") || e["title"]["value"] || ""
      description = e.dig("description_lang","value") || e.dig("description","value") || ""
      startDate = e.dig("startDate","value") || ""
      place = e.dig("place_lang","value") || e.dig("place","value") || ""
      image = e.dig("image","value") || ""
      entity_uri = e.dig("uri","value") || ""
      entities << Entity.new(title: title, description: description, date: startDate,  place: place, image: image, entity_uri: entity_uri)
    end
    entities
  end

  # Class method that returns full graph of individual entity
  def self.find(entity_uri)
    entity = Entity.new(entity_uri: entity_uri)

    # load upper ontology into entity
    solution =  entity.upper_ontology_query.execute(entity.graph).first
    if solution 
      entity.title = solution.title if solution.bound?(:title)
      entity.description = solution.description.value if solution.bound?(:description)
      entity.date_of_first_performance = solution.startDate.value if solution.bound?(:startDate)
      entity.location_label = solution.placeName if  solution.bound?(:placeName)
      entity.main_image = solution.image if  solution.bound?(:image)
    end
    entity
  end

  def layout(spotlight_id)
    @layout_id = spotlight_id
    layout_turtle = Spotlight.find(spotlight_id).layout
    graph.from_ttl(layout_turtle, prefixes: {rdf: RDF.to_uri, cit: "<http://culture-in-time.org/ontology/>"})
 
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
    PREFIX onto: <http://www.ontotext.com/>
    
    CONSTRUCT {
      <#{@entity_uri}> ?p ?o .
      ?p rdfs:label ?label .
      ?o rdfs:label ?o_label . 
      } 
    FROM onto:disable-sameAs
    WHERE { 
      <#{@entity_uri}> ?p ?o . 
      OPTIONAL { ?p rdfs:label ?label_en . filter(lang(?label_en) = "en") }
      OPTIONAL { ?p rdfs:label ?label_fr . filter(lang(?label_fr) = "fr") }
      OPTIONAL { ?p rdfs:label ?label_de . filter(lang(?label_de) = "de") }
      OPTIONAL { ?p rdfs:label ?label_no_language . filter(lang(?label_no_language) = "") }

      BIND(COALESCE(?label_#{I18n.locale.to_s},?label_en, ?label_fr ,?label_de, ?label_no_language ) as ?label)

      OPTIONAL { ?o rdfs:label ?o_label_en . filter(lang(?o_label_en) = "en") }
      OPTIONAL { ?o rdfs:label ?o_label_fr . filter(lang(?o_label_fr) = "fr") }
      OPTIONAL { ?o rdfs:label ?o_label_de . filter(lang(?o_label_de) = "de") }
      OPTIONAL { ?o rdfs:label ?o_label_no_language . filter(lang(?o_label_no_language) = "") }

      BIND(COALESCE(?o_label_#{I18n.locale.to_s},?o_label_en, ?o_label_fr ,?o_label_de, ?o_label_no_language ) as ?o_label)
  

    }
    SPARQL
    
    response = RDFGraph.construct(sparql)
    if response[:code] == 200
      graph << JSON::LD::API.toRdf(response[:message])
    end
    graph
  end
  

  def properties_with_labels
    query = SPARQL.parse(<<~SPARQL)
    PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
    PREFIX cit:  <http://culture-in-time.org/ontology/>
    SELECT distinct ?label ?p ?o ?o_label
    WHERE { 
      ?s ?p ?o  .
      OPTIONAL { ?o rdfs:label ?o_label . } 
      OPTIONAL { ?p rdfs:label ?label  . } 
     # filter(Bound(?label))
     filter(?label != "label")
   #   filter(?o != "")
      bind(LCASE(?label) as ?label_lowercase)
    } 
    order by ?label_lowercase
    SPARQL

    @properties_with_labels ||= query.execute(graph).to_json
    
  end

  def properties_with_labels_layout
    query = SPARQL.parse(<<~SPARQL)
    PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
    PREFIX cit:  <http://culture-in-time.org/ontology/>
    SELECT distinct ?label ?p ?o ?o_label
    WHERE { 
      ?s ?p ?o .
      OPTIONAL { ?o rdfs:label ?o_label .}
      OPTIONAL { ?p rdfs:label ?label .}
      ?p cit:order ?order .
      filter(?label != "label")
     # filter(?o != "")
    } 
    order by ?order
    SPARQL

    @properties_with_labels_layout ||= query.execute(graph).to_json
    
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