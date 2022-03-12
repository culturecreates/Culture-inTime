
class Entity
  attr_accessor :title, :description, :date_of_first_performance, :location_label, :main_image, :entity_uri

  def initialize(title = '', description = '', date = '', place = '', image = '', entity_uri = '')
    @title = title
    @description = description
    @date_of_first_performance = date
    @location_label = place
    @main_image = image
    @entity_uri = entity_uri
  end

  def self.all
    
  end

  def load_solution(solution)
    @title = solution.title if solution.bound?(:title)
    @description = solution.description.value if solution.bound?(:description)
    @date_of_first_performance = solution.startDate.value if solution.bound?(:startDate)
    @location_label = solution.placeName if  solution.bound?(:placeName)
    @main_image = solution.image if  solution.bound?(:image)
    @entity_uri = solution.production.value
  end

  def method_missing(m,*args,&block)
    if m.to_s == 'main_image'
      ""
    else
      "missing"
    end 
  end

end