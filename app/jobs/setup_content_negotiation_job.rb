class SetupContentNegotiationJob < ApplicationJob
  queue_as :default

  def perform(*args)
    uri_list = args[0]
    graph_name = args[1]
    type_uri = args[2]

    uri_list.each do |uri|
      BatchContentNegotiationJob.perform_later(uri, graph_name, type_uri)
    end
    # BatchUpdateJob.perform_later(fix_wikidata_property_labels_sparql)
   #  BatchUpdateJob.perform_later(convert_wikidata_to_rdf_star_sparql)
   #  BatchUpdateJob.perform_later(apply_upper_ontology_sparql)
    
  end
end