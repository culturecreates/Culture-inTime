

# Class to load productions from sparql into local db
class LoadPerformances

  def initialize
    @client = ArtsdataAPI::V1::Client.new()
  end

  def canada(production_uri)
    @client.execute_sparql(SparqlLoader.load("canadian_performances", 
      ["https://www.lavitrineduquebec.com/activity/Femme_s_#Event", 
      production_uri]))
  end

end