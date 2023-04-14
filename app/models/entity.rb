
class Entity
  attr_accessor :title, :description, :date_entity, :location_label, :main_image, :entity_uri, :layout_id

  def initialize(**h) 
    @title = h[:title]
    @description = h[:description]
    @date_entity = h[:date]
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
    # puts "results[:message] #{results[:message]}"
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
    limit = params[:limit] ||= 20
    start_offset = limit.to_i*(@page.to_i - 1)
    end_offset = limit.to_i*(@page.to_i) - 1
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
      entity.date_entity = solution.startDate.value if solution.bound?(:startDate)
      entity.location_label = solution.placeName if  solution.bound?(:placeName)
      entity.main_image = solution.image if  solution.bound?(:image)
    end
    entity
  end

  def layout(spotlight_id)
    @layout_id = spotlight_id
    spotlight = Spotlight.find(spotlight_id)
    layout_turtle = spotlight.layout
    graph.from_ttl(layout_turtle, prefixes: {rdf: RDF.to_uri, cit: "<http://culture-in-time.org/ontology/>"})

    @spotlight_frame = spotlight.frame
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

  def framed_graph
    # frame_json = {  "@context"=> {
    #   "@vocab" =>"http://schema.org/",
    #   "cit"=>"http://culture-in-time.org/ontology/"
    # },
    #  "@explicit"=> true,
    #  "cit:description" =>{"@language"=> "en", "@value"=> {}},
    #  "http://www.wikidata.org/prop/P31" => {}
    # }
    begin
      frame_json = JSON.parse(@spotlight_frame)
    rescue => exception
      Rails.logger.error exception
    end
      
    if frame_json.class == Hash
      puts "framing......"
     JSON::LD::API.frame( JSON.parse(graph.to_jsonld), frame_json)
    end
  end

  # Loads details of a URI in graph format
  # Input: Production URI string
  # Output: RDF Graph
  def load_graph_non_wikidata
    graph = RDF::Graph.new
    sparql = <<~SPARQL
    PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#> 
    PREFIX onto: <http://www.ontotext.com/>
    
    CONSTRUCT {
      <#{@entity_uri}> ?p ?o  .
      ?p rdfs:label ?label .
      ?o rdfs:label ?o_label . 
      } 
    FROM onto:disable-sameAs
    WHERE { 
      <#{@entity_uri}> ?p ?o.
 
      bind(URI(concat("http://www.wikidata.org/prop/direct/P",strafter(str(?p),"/P"))) as ?prop_dir  )
      OPTIONAL {  ?prop_dir rdfs:label ?label_en . filter(lang(?label_en) = "en") }
      OPTIONAL {  ?prop_dir rdfs:label ?label_fr . filter(lang(?label_fr) = "fr") }
      OPTIONAL {  ?prop_dir rdfs:label ?label_de . filter(lang(?label_de) = "de") }
      OPTIONAL {  ?prop_dir rdfs:label ?label_no_language . filter(lang(?label_no_language) = "") }

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


  def load_graph
    sparql = <<~SPARQL
      PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#> 
      PREFIX onto: <http://www.ontotext.com/>
      CONSTRUCT {
        ?s ?p ?o  .
        <<?s ?p ?o>> ?a ?b .
        ?o rdfs:label ?obj_label .
        ?p rdfs:label ?prop_label .
      }
      WHERE {
        values ?s { <#{@entity_uri}> }
        ?s ?p ?o  .
        OPTIONAL {
          <<?s ?p ?o>> ?a ?b .
        }
        filter(contains(str(?p),"/prop/direct/"))

        OPTIONAL {
          ?o rdfs:label ?obj_label .
          filter(lang(?obj_label) = "#{I18n.locale.to_s}")
        }
        OPTIONAL {
          ?p rdfs:label ?prop_label .
          filter(lang(?prop_label) = "#{I18n.locale.to_s}")
        }
      }
      SPARQL
    response = RDFGraph.construct_turtle_star(sparql)
    if response[:code] == 200
      graph = RDF::Graph.new do |graph|
        RDF::Turtle::Reader.new(response[:message], rdfstar: true) {|reader| graph << reader}
      end
    end
    graph
  end



  # Loads details of a URI from WIKIDATA in graph format
  # Input: Production URI string
  # Output: RDF Graph
  def load_graph_old
    graph = RDF::Graph.new
    sparql = <<~SPARQL
      PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#> 
      PREFIX onto: <http://www.ontotext.com/>
      CONSTRUCT {
          ?s ?p ?stat .
          ?s ?cit_prop ?cit_obj .
          ?stat ?stat_prop ?stat_obj .
          ?stat ?qual_prop ?qual_obj .
          ?qual_prop rdfs:label ?qual_label .
          ?stat_obj rdfs:label ?obj_label .
          ?stat_prop rdfs:label ?prop_label .
      }  
      #select  ?s  ?p ?stat   ?stat_prop ?stat_obj ?prop_label  ?obj_label ?qual_obj  ?qual_label
      WHERE {
        {

        }
          values ?s { <#{@entity_uri}> }
          ?s ?cit_prop ?cit_obj .
          filter(contains(str(?cit_prop),"http://culture-in-time.org"))
          ?s ?p ?stat .
          ?stat ?stat_prop ?stat_obj .
          filter(contains(str(?p),"/prop/P")) # only follow down /prop/ and not /prop/direct/
          filter(contains(str(?stat_prop),"/prop/statement/"))
          OPTIONAL {
              ?stat ?qual_prop ?qual_obj 
              filter(contains(str(?qual_prop),"/prop/qualifier/"))
              ?qual_prop rdfs:label ?qual_label .
              filter(lang(?qual_label) = "#{I18n.locale.to_s}")
          }
          OPTIONAL {
              ?stat_obj rdfs:label ?obj_label .
              filter(lang(?obj_label) = "#{I18n.locale.to_s}")
          }
          OPTIONAL {
              bind(URI(concat("http://www.wikidata.org/prop/direct/P",strafter(str(?stat_prop),"/P"))) as ?prop_dir )
              ?prop_dir rdfs:label ?prop_label .
              filter(lang(?prop_label) = "#{I18n.locale.to_s}")
          }
      }
      SPARQL
    
    response = RDFGraph.construct(sparql)
    if response[:code] == 200
      graph << JSON::LD::API.toRdf(response[:message])
    end
    graph
  end


  def entity_properties
    # to do: pass in uri @id to pass to frame
    JSON.parse(graph.dump(:jsonld)).select { |obj| obj["@id"] == "http://www.wikidata.org/entity/Q110835489"}
  
  end

  def properties_with_labels
    query = SPARQL.parse(<<~SPARQL)
    PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
    PREFIX cit:  <http://culture-in-time.org/ontology/>
    select  distinct ?stat_prop ?stat_obj ?prop_label  ?obj_label ?qual_obj  ?qual_label
    WHERE {
      <#{@entity_uri}> ?p ?stat .
        ?stat ?stat_prop ?stat_obj .
        filter(contains(str(?p),"/prop/P")) # only follow down /prop/ and not /prop/direct/
        filter(contains(str(?stat_prop),"/prop/statement/"))  # only follow statements
        filter(!contains(str(?stat_obj),"http://www.wikidata.org/value/")) # Unneeded statement for dateTime
        OPTIONAL {
            ?stat ?qual_prop ?qual_obj 
            filter(contains(str(?qual_prop),"/prop/qualifier/"))  # only follow qualifiers
            ?qual_prop rdfs:label ?qual_label . 
            filter(!contains(str(?qual_obj),"http://www.wikidata.org/value/")) # Unneeded statement for dateTime
        }
        
        optional { ?stat_prop rdfs:label ?prop_label . }
        optional {  ?stat_obj rdfs:label ?obj_label . }
  
      bind(LCASE(?prop_label) as ?label_lowercase)
    
    } 
    order by ?label_lowercase   ?obj_label ?qual_prop # to group properties together
    SPARQL

    @properties_with_labels ||= query.execute(graph).to_json
    
  end

  def properties_with_labels_layout
    query = SPARQL.parse(<<~SPARQL)
    PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
    PREFIX cit:  <http://culture-in-time.org/ontology/>
    select  distinct ?stat_prop ?order ?stat_obj ?prop_label  ?obj_label ?qual_obj  ?qual_label
    WHERE {
      <#{@entity_uri}> ?p ?stat .
        ?stat ?stat_prop ?stat_obj .
        ?stat_prop cit:order ?order .
        filter(contains(str(?p),"/prop/P")) # only follow down /prop/ and not /prop/direct/
        filter(contains(str(?stat_prop),"/prop/statement/"))  # only follow statements
        filter(!contains(str(?stat_obj),"http://www.wikidata.org/value/")) # Unneeded statement for dateTime
        OPTIONAL {
            ?stat ?qual_prop ?qual_obj 
            filter(contains(str(?qual_prop),"/prop/qualifier/"))  # only follow qualifiers
            ?qual_prop rdfs:label ?qual_label . 
            ?qual_prop cit:order ?order2 .
        }
        
        optional { ?stat_prop rdfs:label ?prop_label . }
        optional {  ?stat_obj rdfs:label ?obj_label . }
  
      bind(LCASE(?prop_label) as ?label_lowercase)
    
    } 
    
    order by ?order   ?obj_label 
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