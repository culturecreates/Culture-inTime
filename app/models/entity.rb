
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
      title = e.dig("title_lang","value") || e.dig("title","value") || ""
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

  # Class method that returns full graph of entity uri in object position
  def self.derived(entity_uri)
    entity = Entity.new(entity_uri: entity_uri)
    entity.graph(approach: "derived")
    entity
  end

  # Class method that returns full graph of a uri 
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

  # TO DELETE
  # def layout(spotlight_id)
  #   @layout_id = spotlight_id
  #   spotlight = Spotlight.find(spotlight_id)
  #   layout_graph = RDF::Graph.new
  #   layout_graph.from_ttl(spotlight.layout, prefixes: {rdf: RDF.to_uri, cit: "<http://culture-in-time.org/ontology/>"})
  # end


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

    puts JSON.pretty_generate(result)
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
                  'languages_placeholder' ,   language.split(",").join("\" \"")
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

end