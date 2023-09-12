# Module for Artsdata.ca API
module ArtsdataApi
  module V1
    # Main Client for Artsdata.ca
    # Returns Hash { code: 200|204|... , message: error string or hash }
    # code: 200 is success for SPARQL queries
    # code: 204 is success for SPARQL updates
    class Client
      API_ENDPOINT = ENV['GRAPH_API_ENDPOINT'].freeze
      GRAPH_REPOSITORY = ENV['GRAPH_REPOSITORY'].freeze

      def initialize(oauth_token: nil, graph_repository: GRAPH_REPOSITORY)
        @oauth_token = oauth_token
        @graph_repository = graph_repository
        @logger = Rails.logger
      end

      # Send SPARQL to query endpoint
      # Returns JSON
      def execute_sparql(sparql)
        @logger.info "sparql: #{sparql.truncate(8000).squish}"
        begin
          data = request_json(
            http_method: :post,
            endpoint: "/repositories/#{@graph_repository}",
            params: { 'query': escape_sparql(sparql) }
          )
        rescue => exception
         
          data = OpenStruct.new({status: 500, body:"Error in connection: #{exception.inspect}"})
          
        end
    
        msg = if data.status == 200
                j = Oj.load(data.body)
                j['results']['bindings']
              else
                data.body
              end

        { code: data.status, message: msg }
      end

      # Send SPARQL construct query to endpoint
      # Returns JSON-LD
      def execute_construct_sparql(sparql)
        @logger.info "sparql: #{sparql.truncate(8000).squish}"
        data = request_jsonld(
          http_method: :post,
          endpoint: "/repositories/#{@graph_repository}",
          params: { 'query': escape_sparql(sparql) }
        )

        msg = if data.status == 200
                Oj.load(data.body)
              else
                data.body
              end

        { code: data.status, message: msg }
      end

      # Send SPARQL construct query to endpoint
      # Returns TURTLE
      def execute_construct_turtle_star_sparql(sparql)
        @logger.info "sparql: #{sparql.truncate(8000).squish}"
        data = request_turtle_star(
          http_method: :post,
          endpoint: "/repositories/#{@graph_repository}",
          params: { 'query': escape_sparql(sparql) }
        )

        { code: data.status, message: data.body }
      end

      # Send update SPARQL to '/statements' endpoint
      def execute_update_sparql(sparql)
        @logger.info "sparql update: #{sparql.truncate(8000).squish}"

        data = request_text(
          http_method: :post,
          endpoint: "/repositories/#{@graph_repository}/statements",
          params: { 'update': escape_sparql(sparql) }
        )
        
        { code: data.status, message: data.body }
      end

      # Send turtle data to '/rdf-graphs/service' endpoint
      def upload_turtle(turtle_data, graph_name)
        @logger.info "Uploading turtle data to: #{graph_name}"
        data = add_turtle(
          endpoint: "/repositories/#{@graph_repository}/rdf-graphs/service?graph=#{graph_name}",
          params: turtle_data
        )
        @logger.info "Response: #{data.status} #{data.body}"
        { code: data.status, message: data.body }
        #@client.headers['Content-Type'] = 'text/turtle'
        #response = @client.public_send(:put, "#{txid}?action=ADD", @graph.dump(:ttl, prefixes: {schema: "http://schema.org/"}) )
      end

      # Drop a graph
      def drop_graph(graph_name)
        @logger.info "Dropping graph: #{graph_name}"
        data = request_text(
          http_method: :delete,
          endpoint: "/repositories/#{@graph_repository}/rdf-graphs/service?graph=#{graph_name}"
        )
        { code: data.status, message: data.body }
      end

      private

      def client
        @client ||= Faraday.new(API_ENDPOINT) do |client|
          client.request :url_encoded
          client.adapter Faraday.default_adapter
          client.headers['Authorization'] = "Basic #{@oauth_token}" if @oauth_token.present?
          client.options.timeout = 300 # seconds or about 5 minutes for long updates of 10 MB of data
        end
      end

      # Format str to not interfere with SPARQL
      def escape_sparql sparql
        sparql.gsub(/'/, "\\\\'") # escape single quote
              .gsub('\\', ' ') # remove double backslash
      end

      def request_text(http_method:, endpoint:, params: {})
        client.headers['Accept'] = 'application/json'
        client.headers['Content-Type'] = 'application/x-www-form-urlencoded; charset=UTF-8'
        client.public_send(http_method, endpoint, params)
      end

      def request_json(http_method:, endpoint:, params: {})
        client.headers['Accept'] = 'application/json'
        client.headers['Content-Type'] = 'application/x-www-form-urlencoded; charset=UTF-8'

        client.public_send(http_method, endpoint, params)
      end

      def request_jsonld(http_method:, endpoint:, params: {})
        client.headers['Accept'] = 'application/ld+json'
        client.headers['Content-Type'] = 'application/x-www-form-urlencoded; charset=UTF-8'
        client.public_send(http_method, endpoint, params)
      end

      def request_turtle_star(http_method:, endpoint:, params: {})
        client.headers['Accept'] = 'text/x-turtlestar'
        client.headers['Content-Type'] = 'application/x-www-form-urlencoded; charset=UTF-8'
        client.public_send(http_method, endpoint, params)
      end

      # Use with graph-store API
      def add_turtle(endpoint:, params: {})
        client.headers['Content-Type'] = 'text/turtle'
        client.public_send(:post, endpoint, params)
      end
    end
  end
end
