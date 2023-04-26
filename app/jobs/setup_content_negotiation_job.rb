class SetupContentNegotiationJob < ApplicationJob
  queue_as :default

  def perform(*args)
    uri_list = args[0]
    graph_name = args[1]
    type_uri = args[2] || nil

    uri_list.each do |uri|
      BatchContentNegotiationJob.perform_later(uri, graph_name, type_uri)
    end
  
    
  end

end