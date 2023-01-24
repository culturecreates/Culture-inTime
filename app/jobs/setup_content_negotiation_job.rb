class SetupContentNegotiationJob < ApplicationJob
  queue_as :default

  def perform(*args)
    uri_list = args[0]
    graph_name = args[1]
    type_uri = args[2]

    uri_list.each do |uri|
      BatchContentNegotiationJob.perform_later(uri, graph_name, type_uri)
    end
    BatchUpdateJob.perform_later(generate_fix_wikidata_labels_sparql)
    BatchUpdateJob.perform_later(generate_upper_ontology_sparql)
  end
end