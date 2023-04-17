class SetupSecondaryContentNegotiationJob < ApplicationJob
  queue_as :default

  def perform(*args)
    uri_list = args[0]
    graph_name = args[1]

    uri_list.each do |uri|
      BatchContentNegotiationJob.perform_later(uri, graph_name, nil)
    end
    BatchUpdateJob.perform_later(fix_wikidata_property_labels_sparql)
    BatchUpdateJob.perform_later(convert_wikidata_to_rdf_star_sparql)
    
  end
end