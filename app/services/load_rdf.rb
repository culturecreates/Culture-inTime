# Class to load data from sparql into graphdb
class LoadRDF
  attr_accessor :sample_uri

  def initialize
    @client = ArtsdataApi::V1::Client.new()
    @cache_errors = []
  end

  # Main method to load or refresh a source
  # Drop and load Productions from SPARQL
  # Input: activeRecord DataSource
  def source(data_source)
    @data = @client.execute_sparql(data_source.sparql)
 

    return if self.error?
    # Load new productions
    @graph = load(data_source, @data[:message])

    # Only update loaded data if some productions were saved to db
    return unless @graph.count.positive?
    
    # persist to graphDB
    RDFGraph.graph << @graph
    RDFGraph.persist(data_source.id)
    data_source.update_attribute(:loaded, Time.now)
  end

  def sample
    @sample_uri = @data[:message].first['uri']['value']
    query = SPARQL.parse("CONSTRUCT {<#{@sample_uri}> ?p ?o .} WHERE { <#{@sample_uri}> ?p ?o .}")
    query.execute(@graph).to_jsonld
  end

  def error?
    @data[:code] != 200
  end

  def errors
    return unless @data[:code] != 200
    @data[:message]
  end

  def count
    return 0 unless @data[:code] == 200
    @data[:message].count
  end

  def cache_errors
    @cache_errors
  end

  private

  def load(data_source, data)
    graph = RDF::Graph.new
    data.each do |resource|
      uri = resource['uri']['value']  if resource['uri']
      begin
        graph << RDF::Graph.load(uri)
        graph << [RDF::URI(uri), RDF.type, RDF::URI(data_source.type_uri)]
      rescue => exception
        cache_errors << [uri, exception]  unless cache_errors.count > 10 #max errors
      end
    end
    graph
  end
end
