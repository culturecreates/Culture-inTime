class Spotlight < ApplicationRecord
  has_and_belongs_to_many :data_sources, after_add: :set_data_sources_changed, after_remove: :set_data_sources_changed

  validates :title, :description, :location, :subtitle, presence: true

  before_save :remove_sparql_line_feeds, :check_if_search_params_changed
 
  # returns a string of properties for use as sparql values
  def forward_prop_values
    Layout.new(self.layout).fields.map {|f| "<#{f.first.first}>" if f.first.first.include?("prop/direct") && f[:direction].include?("Forward") }.join(" ") 
  end

  def spotlight_lang_values
    if self.language
      self.language.split(",").map { |l| "\"#{l.squish}\"  " }.join
    else
      ' "en" '  # default english
    end
  end

  def reverse_prop_values
    Layout.new(self.layout).fields.map {|f| "<#{f.first.first}>" if f[:direction].include?("Reverse") }.join(" ") 
  end

  def qualifier_prop_values
    Layout.new(self.layout).fields.map {|f| "<#{f.first.first}>" if f.first.first.include?("prop/qualifier") && f[:direction].include?("Forward") }.join(" ") 
  end

  def reference_prop_values
    Layout.new(self.layout).fields.map {|f| "<#{f.first.first}>" if f.first.first.include?("prop/reference") && f[:direction].include?("Forward") }.join(" ") 
  end

  def generate_sparql
    SparqlLoader.load('spotlight_index',[
      '<spotlight_query_placeholder> a "triple"', self.sparql,
      'ui_language', I18n.locale.to_s
    ])
  end

  def generate_sparql_stats_prop
    SparqlLoader.load('collect_spotlight_stats_prop',[
      '<spotlight_query_placeholder> a "triple"', self.sparql
    ])
  end
  def generate_sparql_stats_qual
    SparqlLoader.load('collect_spotlight_stats_qual',[
      '<spotlight_query_placeholder> a "triple"', self.sparql
    ])
  end
  def generate_sparql_stats_ref
    SparqlLoader.load('collect_spotlight_stats_ref',[
      '<spotlight_query_placeholder> a "triple"', self.sparql
    ])
  end
  def generate_sparql_stats_inverse_prop
    SparqlLoader.load('collect_spotlight_stats_inverse_prop',[
      '<spotlight_query_placeholder> a "triple"', self.sparql
    ])
  end

  def dump_sparql(uri_values)
    <<~SPARQL
      PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
      PREFIX prov: <http://www.w3.org/ns/prov#>
      construct 
      {
        ?uri ?p ?o .
        ?o rdfs:label ?label .
        ?reverse_sub ?reverse_prop ?uri . 
        ?reverse_sub rdfs:label ?reverse_sub_label .

        << ?uri ?p ?o >> ?qual_prop ?qual_obj .
        ?qual_obj rdfs:label ?qual_label .

        << ?uri ?p ?o >> prov:wasDerivedFrom ?ref_sub .
        ?ref_sub ?ref_prop ?ref_obj .
        ?ref_obj rdfs:label ?ref_label .
      }
      where {
          values ?uri { #{uri_values} }
          values ?p { #{forward_prop_values} } 
          #{ "values ?qual_prop { " + qualifier_prop_values + "}" if !qualifier_prop_values.blank? }
          #{ "values ?ref_prop { " + reference_prop_values + "}" if !reference_prop_values.blank? }
          #{ "values ?reverse_prop { " + reverse_prop_values + "}" if !reverse_prop_values.blank? }
          values ?lang { #{spotlight_lang_values} }
          ?uri ?p ?o .
          ?o rdfs:label ?label .
          filter(lang(?label) = ?lang)

          OPTIONAL {
            ?reverse_sub ?reverse_prop ?uri . 
            OPTIONAL {
              ?reverse_sub rdfs:label ?reverse_sub_label .
              filter(lang(?reverse_sub_label) = ?lang) 
            }
           
          }
          OPTIONAL {
            << ?uri ?p ?o >> ?qual_prop ?qual_obj .
              OPTIONAL {
                  ?qual_obj rdfs:label ?qual_label .
                  filter(lang(?qual_label) = ?lang) 
              }
          }
          OPTIONAL {
            << ?uri ?p ?o >> prov:wasDerivedFrom ?ref_sub .
            OPTIONAL {
              ?ref_sub ?ref_prop ?ref_obj .
              OPTIONAL {
                ?ref_obj rdfs:label ?ref_label .
              }
            }
          }
      }
    SPARQL
  end

  # Class method that returns a graph of all entities in spotlight
  def compile_dump_graph
    uri_values = Entity.spotlight(self).uri_values
    sparql = dump_sparql(uri_values)
    response = RDFGraph.construct_turtle_star(sparql)
    if response[:code] == 200
      RDF::Graph.new do |graph|
        RDF::Turtle::Reader.new(response[:message], rdfstar: true) {|reader| graph << reader}
      end
    else
      RDF::Graph.new
    end
   
  end

  private 

  def remove_sparql_line_feeds
    # clear the line feeds in sparql otherwise it will trigger a changed_attributes 
    self.sparql.gsub!(/\r/,"")  if self.sparql
  end

  def set_data_sources_changed(record)
    @data_sources_changed = true
  end

  def check_if_search_params_changed
    if changed_attributes["sparql"].present?
      self.start_date = nil
      self.end_date = nil
      self.query = nil
    else
      return unless (["start_date", "end_date", "query"] & changed_attributes.keys).present? || @data_sources_changed
      
      data_source_filter = if self.data_sources.count 
        <<~SPARQL
          values ?graph { #{self.data_sources.map { |s| "<#{s.graph_name}> "}.join } }
          values ?type_uri { #{self.data_sources.map { |s|  "<#{s.type_uri}> "}.join } }
          graph ?graph {
            ?uri a ?type_uri
          }
        SPARQL
      else
        ""
      end
      start_date_filter = self.start_date.present? ?  " ?uri cit:startDate ?date . filter(?date > \"#{self.start_date.iso8601}T00:00:00Z\"^^xsd:dateTime) " : "" 
      end_date_filter = self.end_date.present? ?  " ?uri cit:startDate ?date . filter(?date < \"#{self.end_date.iso8601}T00:00:00Z\"^^xsd:dateTime) " : "" 
      query_filter = self.query.present? ?  " optional { ?uri ?upper_prop  ?query . filter(contains(lcase(?query),\"#{self.query.downcase}\")) }" : "" 
      
      sparql = <<~SPARQL
      select distinct ?uri where {
      #{data_source_filter}
      values ?upper_prop { cit:title cit:description cit:placeName }
      filter (bound(?uri))
      #{start_date_filter}
      #{end_date_filter}
      #{query_filter}
      }
      SPARQL
  
      self.sparql = sparql
    end
   

  end


end
