class Spotlight < ApplicationRecord
  has_and_belongs_to_many :data_sources

  validates :title, :description, :location, :subtitle, presence: true



  def generate_sparql
    SparqlLoader.load('spotlight_productions',[
      '<spotlight_query_placeholder> a "triple"', self.sparql
    ])
  end
end
