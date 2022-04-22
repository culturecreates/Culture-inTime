class Spotlight < ApplicationRecord
  has_and_belongs_to_many :data_sources

  validates :title, :description, :location, :subtitle, presence: true



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
end
