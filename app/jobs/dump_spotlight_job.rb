class DumpSpotlightJob < ApplicationJob
  queue_as :default

  # Params: 0 -> spotlight id
  def perform(*args)
    @logger = Rails.logger
    @spotlight = Spotlight.find(args[0])
    data = Entity.spotlight(@spotlight)
    props =  @spotlight.forward_prop_values
    reverse = @spotlight.reverse_prop_values
    qualifiers =  @spotlight.qualifier_prop_values
    qualifiers = "<http://none.com>" if qualifiers.blank?
    references =  @spotlight.reference_prop_values
    references = "<http://none.com>" if references.blank?
    spotlight_lang = @spotlight.spotlight_lang_values
    graph = RDF::Graph.new
    data.paginate(limit:10000).each_with_index do |entity, index|
      entity.graph(
        approach: "wikidata", 
        language: spotlight_lang,
        props: props,
        reverse: reverse,
        qualifiers: qualifiers,
        references: references
      )
      json_framed = entity.framed_graph
      g =  RDF::Graph.new
      graph << g.from_jsonld(json_framed.to_json)
      # sleep(0.2) # part of a second
      @logger.info "index ---------------> #{index + 1} of #{data.count}"
    end

    frame_json = nil
    if @spotlight.frame.present?
      begin
        frame_json = JSON.parse(@spotlight.frame)
      end
    end
    
    if frame_json.class == Hash
      puts "framing......"
      output = JSON::LD::API.frame( JSON.parse(graph.to_jsonld), frame_json)
      @spotlight.dump = output.to_json
      @spotlight.save
    else
      puts "invalid frame....saving JSON-LD without frame."
      output = graph.dump(:jsonld, validate: false)
      @spotlight.dump = output
      @spotlight.save
    end
    
  end
end
