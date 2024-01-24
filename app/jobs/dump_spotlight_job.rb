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
    all_entities = {"@context"=>JSON.parse(@spotlight.frame)["@context"],"@graph"=>[]}
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
      all_entities["@graph"] << json_framed.except("@context")
      @logger.info "index ---------------> #{index + 1} of #{data.count}"
    end
    @logger.info "Saving dump to spotlight....."
    @spotlight.dump = all_entities.to_json
    @spotlight.save
    
  end
end
