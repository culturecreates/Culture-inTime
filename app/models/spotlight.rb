class Spotlight < ApplicationRecord
  has_and_belongs_to_many :data_sources

  validates :title, :description, :location, :subtitle, presence: true

  before_save :remove_line_feed
  before_save :check_if_search_params_changed



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


  def remove_line_feed
    # clear the line feed otherwise it will trigger a change in sparql
    self.sparql.gsub!(/\r/,"")  if self.sparql
  end

  def check_if_search_params_changed
    if changed_attributes["sparql"].present?
      puts "sparql changed...#{changes}"
      self.start_date = nil
      self.end_date = nil
      self.query = nil
    else
      return unless (["start_date", "end_date", "query"] & changed_attributes.keys).present?
      puts "#{changed_attributes.keys} changed..."

      start_date_filter = self.start_date.present? ?  " ?uri cit:startDate ?date . filter(?date > \"#{self.start_date.iso8601}T00:00:00Z\"^^xsd:dateTime) " : "" 
      end_date_filter = self.end_date.present? ?  " ?uri cit:startDate ?date . filter(?date < \"#{self.end_date.iso8601}T00:00:00Z\"^^xsd:dateTime) " : "" 
      query_filter = self.query.present? ?  " optional { ?uri ?upper_prop  ?query . filter(contains(lcase(?query),\"#{self.query.downcase}\")) }" : "" 
      
      sparql = <<~SPARQL
      select distinct ?uri where {
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
