
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
    entity.graph
    entity
  end

  def layout(spotlight_id)
    @layout_id = spotlight_id
    spotlight = Spotlight.find(spotlight_id)
    @spotlight_frame = spotlight.frame
    layout_turtle = spotlight.layout
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


  def entity_properties
    # todo: use sparql or framing to avoid looping  
    JSON.parse(graph.dump(:jsonld)).select { |obj| obj["@id"] == @entity_uri}
  
  end

  def spotlight_properties
    frame_file = "app/services/frames/entity.jsonld"
    frame = JSON.parse(File.read(frame_file))
    input = JSON.parse(graph.dump(:jsonld))

    JSON::LD::API.frame( input, frame, rdfstar: true)

    #JSON.parse(graph.dump(:jsonld)).select { |obj| obj["@id"] == @entity_uri}
  end



  def load_graph
    sparql = <<~SPARQL
      PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#> 
      PREFIX onto: <http://www.ontotext.com/>
      CONSTRUCT {
        ?s ?p ?o  .
        <<?s ?p ?o>> ?a ?b .
        <<?s ?p ?o>> <http://www.w3.org/ns/prov#wasDerivedFrom> ?c .
        ?c ?cp ?co .
        ?cp rdfs:label ?cp_label .
        ?co rdfs:label ?co_label .
        ?p rdfs:label ?prop_label .
        ?o rdfs:label ?obj_label .
        ?a rdfs:label ?a_label .
        ?b rdfs:label ?b_label .
      }
      WHERE {
        values ?s { <#{@entity_uri}> }
        ?s ?p ?o  .
        filter(!contains(str(?p),"/prop/P"))
        OPTIONAL {
          ?o rdfs:label ?obj_label .
          filter(lang(?obj_label) = "#{I18n.locale.to_s}")
        }
        OPTIONAL {
          ?p rdfs:label ?prop_label .
          filter(lang(?prop_label) = "#{I18n.locale.to_s}" || "")
        }

        OPTIONAL {
          <<?s ?p ?o>> ?a ?b .
        }
        OPTIONAL {
          <<?s ?p ?o>> ?a ?b .
          ?a rdfs:label ?a_label . 
          filter(lang(?a_label) = "#{I18n.locale.to_s}")
        }
        OPTIONAL {
          <<?s ?p ?o>> ?a ?b .
          ?b rdfs:label ?b_label .
          filter(lang(?b_label) = "#{I18n.locale.to_s}")
        }
        OPTIONAL {
          <<?s ?p ?o>> <http://www.w3.org/ns/prov#wasDerivedFrom> ?c .
          ?c ?cp ?co .
        }
        OPTIONAL {
          <<?s ?p ?o>> <http://www.w3.org/ns/prov#wasDerivedFrom> ?c .
          ?c ?cp ?co .
          ?cp rdfs:label ?cp_label .
          filter(lang(?cp_label) = "#{I18n.locale.to_s}")
        }
        OPTIONAL {
          <<?s ?p ?o>> <http://www.w3.org/ns/prov#wasDerivedFrom> ?c .
          ?c ?cp ?co .
          ?co rdfs:label ?co_label .
          filter(lang(?co_label) = "#{I18n.locale.to_s}")
        }
      }
      SPARQL
    response = RDFGraph.construct_turtle_star(sparql)
    if response[:code] == 200
      RDF::Graph.new do |graph|
        RDF::Turtle::Reader.new(response[:message], rdfstar: true) {|reader| graph << reader}
      end
    else
      RDF::Graph.new
    end
    
  end



  # def properties_with_labels
  #   query = SPARQL.parse(<<~SPARQL)
  #   PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
  #   PREFIX cit:  <http://culture-in-time.org/ontology/>
  #   select  distinct ?stat_prop ?stat_obj ?prop_label  ?obj_label ?qual_obj  ?qual_label
  #   WHERE {
  #     <#{@entity_uri}> ?p ?stat .
  #       ?stat ?stat_prop ?stat_obj .
  #       filter(contains(str(?p),"/prop/P")) # only follow down /prop/ and not /prop/direct/
  #       filter(contains(str(?stat_prop),"/prop/statement/"))  # only follow statements
  #       filter(!contains(str(?stat_obj),"http://www.wikidata.org/value/")) # Unneeded statement for dateTime
  #       OPTIONAL {
  #           ?stat ?qual_prop ?qual_obj 
  #           filter(contains(str(?qual_prop),"/prop/qualifier/"))  # only follow qualifiers
  #           ?qual_prop rdfs:label ?qual_label . 
  #           filter(!contains(str(?qual_obj),"http://www.wikidata.org/value/")) # Unneeded statement for dateTime
  #       }
        
  #       optional { ?stat_prop rdfs:label ?prop_label . }
  #       optional {  ?stat_obj rdfs:label ?obj_label . }
  
  #     bind(LCASE(?prop_label) as ?label_lowercase)
    
  #   } 
  #   order by ?label_lowercase   ?obj_label ?qual_prop # to group properties together
  #   SPARQL

  #   @properties_with_labels ||= query.execute(graph).to_json
    
  # end

  # def properties_with_labels_layout
  #   query = SPARQL.parse(<<~SPARQL)
  #   PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
  #   PREFIX cit:  <http://culture-in-time.org/ontology/>
  #   select  distinct ?stat_prop ?order ?stat_obj ?prop_label  ?obj_label ?qual_obj  ?qual_label
  #   WHERE {
  #     <#{@entity_uri}> ?p ?stat .
  #       ?stat ?stat_prop ?stat_obj .
  #       ?stat_prop cit:order ?order .
  #       filter(contains(str(?p),"/prop/P")) # only follow down /prop/ and not /prop/direct/
  #       filter(contains(str(?stat_prop),"/prop/statement/"))  # only follow statements
  #       filter(!contains(str(?stat_obj),"http://www.wikidata.org/value/")) # Unneeded statement for dateTime
  #       OPTIONAL {
  #           ?stat ?qual_prop ?qual_obj 
  #           filter(contains(str(?qual_prop),"/prop/qualifier/"))  # only follow qualifiers
  #           ?qual_prop rdfs:label ?qual_label . 
  #           ?qual_prop cit:order ?order2 .
  #       }
        
  #       optional { ?stat_prop rdfs:label ?prop_label . }
  #       optional {  ?stat_obj rdfs:label ?obj_label . }
  
  #     bind(LCASE(?prop_label) as ?label_lowercase)
    
  #   } 
    
  #   order by ?order   ?obj_label 
  #   SPARQL

  #   @properties_with_labels_layout ||= query.execute(graph).to_json
    
  # end

  # def upper_ontology_query
  #   cit = RDF::Vocabulary.new("http://culture-in-time.org/ontology/")
  #   schema = RDF::Vocabulary.new("http://schema.org/")
  #   query = RDF::Query.new({
  #     production: {
  #       :a => :b
  #     }
  #   }, **{})
  #   query << RDF::Query::Pattern.new(:production, cit.title, :title, optional: true)
  #   query << RDF::Query::Pattern.new(:production, schema.name, :title_schema, optional: true)
  #   query << RDF::Query::Pattern.new(:production, cit.placeName, :placeName, optional: true)
  #   query << RDF::Query::Pattern.new(:production, cit.image, :image, optional: true)
  #   query << RDF::Query::Pattern.new(:production, cit.description, :description, optional: true)
  #   query << RDF::Query::Pattern.new(:production, cit.startDate, :startDate, optional: true)
  #   query
  # end
end