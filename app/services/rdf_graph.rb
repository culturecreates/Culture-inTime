class RDFGraph
  
  def self.graph
    @@graph ||= RDF::Graph.new
    #@@graph ||= RDF::Graph.load('config/initializers/artsdata-dump.nt', format: :nquads)
  end

  def self.all
    entities = []

    query = SPARQL.parse(<<~SPARQL)
    SELECT * 
    WHERE { 
      ?s <http://www.wikidata.org/prop/direct/P31> <http://www.wikidata.org/entity/Q7777570> ; 
        <http://schema.org/description> ?description ; 
        <http://www.wikidata.org/prop/direct/P1191> ?date . 
        ?s <http://www.w3.org/2004/02/skos/core#prefLabel>  ?label  .
        FILTER (lang(?description) = '#{I18n.locale}')
    }
    SPARQL
    results = query.execute(graph).to_json
    JSON.parse(results)['results']['bindings'].each do |e|
      entities << Entity.new(e["label"]["value"], e["description"]["value"])
    end
    entities
  end
end

class Entity
  attr_accessor :label, :description

  def initialize(label, description)
    @label = label
    @description = description
  end

  def method_missing(m,*args,&block)
    if m.to_s == 'main_image'
      ""
    else
      "missing"
    end 
  end

end

