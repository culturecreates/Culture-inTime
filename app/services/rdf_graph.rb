class RDFGraph
  
  def self.graph
    @@graph ||= RDF::Graph.new
    #@@graph ||= RDF::Graph.load('config/initializers/artsdata-dump.nt', format: :nquads)
  end

  # Input: ActiveRecord Spotlight
  def self.spotlight(spotlight)
    entities = []

    # query = SPARQL.parse(<<~SPARQL)
    # SELECT * 
    # WHERE { 
    #   ?s <http://www.wikidata.org/prop/direct/P31> <http://www.wikidata.org/entity/Q7777570> ; 
    #     <http://schema.org/description> ?description ; 
    #     <http://www.wikidata.org/prop/direct/P1191> ?date . 
    #     ?s <http://www.w3.org/2004/02/skos/core#prefLabel>  ?label  .
    #     FILTER (lang(?description) = '#{I18n.locale}')
    # }
    # SPARQL
    # results = query.execute(graph).to_json

    results =  artsdata_client.execute_sparql(generate_query_sparql(spotlight))

    results[:message].each do |e|
      title = e["title"]["value"] || ""
      description = e.dig("description","value") || ""
      startDate = e.dig("startDate","value") || ""
      place = e.dig("place","value") || ""
      image = e.dig("image","value") || ""
      entities << Entity.new(title, description, startDate,  place, image)
    end
    entities
  end

  def self.persist(id)
    # artsdata_client.drop_graph(uri(id))
    artsdata_client.upload_turtle(graph.dump(:turtle), uri(id))
  end

  def self.uri(id)
    "http://culture-in-time.com/graph/#{id}"
  end

  def self.upper_ontology(data_source)
    artsdata_client.execute_update_sparql(generate_upper_ontology_sparql(data_source))
  end

  def self.generate_upper_ontology_sparql(data_source)
    SparqlLoader.load('apply_upper_ontology', [
      'graph_placeholder', uri(data_source.id),
      'type_uri_placeholder' , data_source.type_uri,
      '<languages_placeholder>', data_source.upper_languages.split(",").map {|l| "\"#{l}\"" }.join(" "),
      '<title_prop_placeholder>', data_source.upper_title,
      '<date_prop_placeholder>', data_source.upper_date,
      '<description_prop_placeholder>', data_source.upper_description,
      '<place_name_prop_placeholder>', data_source.upper_place,
      '<place_name_country_prop_placeholder>', data_source.upper_country,
      '<image_prop_placeholder>' , data_source.upper_image
    ])
    
  end

  def self.generate_query_sparql(spotlight)
    SparqlLoader.load('spotlight_productions',[])
    
  end

 

  def self.artsdata_client
    @artsdata_client ||= ArtsdataApi::V1::Client.new(oauth_token: "YXJ0c2RhdGEtYXBpOlN5amNpeC16b3Z3ZXMtN3ZvYm1p")
  end
end

class Entity
  attr_accessor :title, :description, :date_of_first_performance, :location_label, :main_image

  def initialize(title, description, date, place, image)
    @title = title
    @description = description
    @date_of_first_performance = date
    @location_label = place
    @main_image = image
  end

  def method_missing(m,*args,&block)
    if m.to_s == 'main_image'
      ""
    else
      "missing"
    end 
  end

end

