class RDFGraph

  def self.execute(sparql)
    artsdata_client.execute_sparql(sparql)
  end

  def self.update(sparql)
    artsdata_client.execute_update_sparql(sparql)
  end

  ## Returns JSON-LD from a construct sparql
  def self.construct(sparql)
    artsdata_client.execute_construct_sparql(sparql)
  end

    ## Returns Turtle Star from a construct sparql
    def self.construct_turtle_star(sparql)
      artsdata_client.execute_construct_turtle_star_sparql(sparql)
    end

  def self.persist(turtle, graph_name)
    artsdata_client.upload_turtle(turtle, graph_name)
  end

  def self.drop(graph_name)
    artsdata_client.drop_graph(graph_name)
  end

  def self.artsdata_client
    @artsdata_client ||= ArtsdataApi::V1::Client.new  # (oauth_token: Rails.application.credentials.dig(:graphdb, :oauth_token))
  end
end


