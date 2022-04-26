class Spotlight < ApplicationRecord
  has_and_belongs_to_many :data_sources, after_add: :set_data_sources_changed, after_remove: :set_data_sources_changed

  validates :title, :description, :location, :subtitle, presence: true

  before_save :remove_sparql_line_feeds, :check_if_search_params_changed




  def generate_sparql
    SparqlLoader.load('spotlight_index',[
      '<spotlight_query_placeholder> a "triple"', self.sparql,
      'ui_language', I18n.locale.to_s
    ])
  end

  def generate_sparql_properties
    SparqlLoader.load('collect_spotlight_properties',[
      '<spotlight_query_placeholder> a "triple"', self.sparql
    ])
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
