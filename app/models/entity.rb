
class EntityCollection
  include Enumerable
  attr_accessor :entities

  def initialize(entities)
    @entities = entities
  end

  def each(&block)
    if block_given?
      entities.each(&block)
    else
      to_enum(:each)
    end
  end

  def paginate(**params)
    page = params[:page] ||= 1
    limit = params[:limit] ||= 20
    start_offset = limit.to_i*(page.to_i - 1)
    end_offset = limit.to_i*(page.to_i) - 1
    EntityCollection.new(entities[start_offset..end_offset])
  end

  def uri_values
    entities.map { |entity|  "<#{entity.entity_uri}>" }.join("  ")
  end

  # Class method that returns a graph of all  entities in spotlight
  def compile_dump_graph(spotlight)
    
    forward_prop_values = spotlight.forward_prop_values
    # reverse_prop_values = 
    sparql = SparqlLoader.load('load_spotlight_dump', [
      '<uri_values_placeholder>', uri_values,
      '<forward_prop_values_placeholder>' , forward_prop_values
    ])
    response = RDFGraph.construct_turtle_star(sparql)
    if response[:code] == 200
      RDF::Graph.new do |graph|
        RDF::Turtle::Reader.new(response[:message], rdfstar: true) {|reader| graph << reader}
      end
    else
      RDF::Graph.new
    end
   end
end

class Entity
  include ::SpotlightsHelper
  attr_accessor :title, :description, :date_entity, :location_label, :main_image, :entity_uri, :layout_id

  def initialize(**h) 
    @title = h[:title]
    @description = h[:description]
    @date_entity = h[:date]
    @location_label = h[:place]
    @main_image = h[:image]
    @entity_uri = h[:entity_uri]
    @layout_id = h[:layout_id]
  end

  # Class method to find all entities given a DataSource id
  # Returns EntityCollection
  def self.data_source(data_source_id)
    data_source = DataSource.find(data_source_id)
    results = RDFGraph.execute(data_source.generate_sparql)
    load_entities(results[:message])
  end

  # Class method to find all entities given a Spotlight id
  # Returns EntityCollection
  def self.spotlight(spotlight)
    if spotlight.class == String
      spotlight = Spotlight.find(spotlight)
    end
    results = RDFGraph.execute(spotlight.generate_sparql)
    load_entities(results[:message])
  end

  # Class method that returns full graph of individual entity
  # Returns an Entity
  def self.find(entity_uri)
    entity = Entity.new(entity_uri: entity_uri)
    entity.graph
    entity
  end

  # Class method that returns Entity 
  # with full graph of entity uri in object position
  def self.derived(entity_uri)
    entity = Entity.new(entity_uri: entity_uri)
    entity.graph(approach: "derived")
    entity
  end

  # Class method that returns Entity
  # with full graph of a uri 
  # with wikidata statement nodes instead of RDF Star
  # with literals in languages chosen by the layout
  def self.wikidata(entity_uri, layout_id = nil)
    puts "layout_id: #{layout_id}"
    
    language_list = if layout_id 
                      Spotlight.find(layout_id).language
                    else
                      "en"
                    end
    entity = Entity.new(entity_uri: entity_uri, layout_id: layout_id)
    entity.graph(approach: "wikidata", language: language_list)
    entity
  end

  def method_missing(m,*args,&block)
    if m.to_s == 'main_image'
      ""
    else
      "missing"
    end 
  end

  def graph(approach: "rdfstar", language: "en")
    # TODO: this should not call load_graph. 
    #       Change code to call load_graph explicitly
    @graph ||= load_graph(approach, language)
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
      if @layout_id
        spotlight = Spotlight.find(@layout_id)
        @spotlight_frame = spotlight.frame
      end
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
    JSON.parse(graph.dump(:jsonld)) #.select { |obj| obj["@id"] == @entity_uri}
  
  end

  def spotlight_properties
    frame_file = "app/services/frames/entity.jsonld"
    frame = JSON.parse(File.read(frame_file))
    input = JSON.parse(graph.dump(:jsonld), validate: false, standard_prefixes: true)

    JSON::LD::API.frame( input, frame)

    #JSON.parse(graph.dump(:jsonld)).select { |obj| obj["@id"] == @entity_uri}
  end

  def test_frame
   
    input =  JSON.parse %({
      "@context": {
        "@base":"http://www.artsdata.ca/resource/",
        "@vocab":"http://www.artsdata.ca/resource/"
      },
      "@graph": [
        {
          "@id": "TheShow",
          "@type": "Performance",
          "performer": {
            "@id": "John",
            "@annotation": {
                "certainty": 1
            }
          }
        },
        {
          "@id": "John",
          "@type": "Person",
          "name" : "John Smith"
        }
      ]
    })

    frame = JSON.parse %({
      "@context": {
        "@base":"http://www.artsdata.ca/resource/",
        "@vocab":"http://www.artsdata.ca/resource/"
       },
       "@type": "Performance"
    })
  
    result = JSON::LD::API.frame(input, frame, rdfstar: true)

    # puts JSON.pretty_generate(result)
    result
  end

  def load_graph(approach = "rdfstar", language = "en")

    sparql =  if approach == "derived"
                SparqlLoader.load('load_derived_graph', [
                  'entity_uri_placeholder', @entity_uri,
                  'languages_placeholder' , language.split(",").join("\" \"")
                ])
              elsif approach == "wikidata"
                SparqlLoader.load('load_wikidata_graph', [
                  'entity_uri_placeholder', @entity_uri,
                  'languages_placeholder' ,  language.split(",").join("\" \"") # "en\" \"fr\" \"de"
                ])
              elsif @layout_id
                SparqlLoader.load('load_rdfstar_graph_layout', [
                  'entity_uri_placeholder', @entity_uri,
                  'locale_placeholder' , I18n.locale.to_s,
                  'layout_graph_placeholder', generate_layout_graph_name(@layout_id) 
                ])
              else 
                SparqlLoader.load('load_rdfstar_graph', [
                  'entity_uri_placeholder', @entity_uri,
                  'locale_placeholder' , I18n.locale.to_s
                ])
              end

    response = RDFGraph.construct_turtle_star(sparql)
    if response[:code] == 200
      RDF::Graph.new do |graph|
        RDF::Turtle::Reader.new(response[:message], rdfstar: true) {|reader| graph << reader}
      end
    else
      RDF::Graph.new
    end
  end


  private

    # Class method that stores results of a SPARQL select and count
    def self.load_entities(sparql_results)
      collection = []
      sparql_results.each do |e|
        title = e.dig("title_lang","value") || e.dig("title","value") || ""
        description = e.dig("description_lang","value") || e.dig("description","value") || ""
        startDate = e.dig("startDate","value") || ""
        place = e.dig("place_lang","value") || e.dig("place","value") || ""
        image = e.dig("image","value") || ""
        entity_uri = e.dig("uri","value") || ""
        collection << new(title: title, description: description, date: startDate,  place: place, image: image, entity_uri: entity_uri)
      end
      EntityCollection.new(collection)
    end

end