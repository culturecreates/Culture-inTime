class DumpSpotlightJob < ApplicationJob
  queue_as :default

  # Params: 0 -> sparql
  def perform(*args)
    @spotlight = Spotlight.find(args[0])
    data = Entity.spotlight(@spotlight)
    # old way -> graph  = @spotlight.compile_dump_graph
    graph = RDF::Graph.new
    data.paginate.each do |entity|
      graph << entity.graph(approach: "wikidata")
      sleep(0.2) # part of a second
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
