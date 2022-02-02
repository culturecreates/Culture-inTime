class RDFGraph
  
  def self.graph
    @@graph ||= RDF::Graph.new
    #@@graph ||= RDF::Graph.load('config/initializers/artsdata-dump.nt', format: :nquads)
  end

  def self.all
    entities = []

    query = SPARQL.parse("SELECT * WHERE { ?s <http://www.wikidata.org/prop/direct/P31> <http://www.wikidata.org/entity/Q7777570> ; <http://schema.org/description> ?description ; <http://www.wikidata.org/prop/direct/P1191> ?date . ?s <http://www.w3.org/2004/02/skos/core#prefLabel>  ?label  .}")
    results = query.execute(graph).to_json
    JSON.parse(results)['results']['bindings'].each do |e|
      entities << Entity.new(e["label"]["value"])
    end
    entities
  end
end

class Entity
  attr_accessor :label

  def initialize(label)
    @label = label
  end

  def method_missing(m,*args,&block)
    if m.to_s == 'main_image'
      ""
    else
      "missing"
    end 
  end

end

