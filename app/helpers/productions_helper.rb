module ProductionsHelper

  require 'digest/md5'

  def production_image(production)
    if production&.main_image.blank?
      if production&.title
        color = Digest::MD5.hexdigest(production&.title)[0..5]
      else
        color = Digest::MD5.hexdigest("missing-title")[0..5]
      end
      "https://dummyimage.com/300x200/#{color}/ffffff.png&text=#{production.title}"
    else
      # Convert wikimedia urls to https to fix image rendering problem. see https://github.com/culturecreates/Culture-inTime/issues/9
      url = if production.main_image.class == String
        production.main_image
      else
        production.main_image.value
      end
      url.gsub("http://commons.wikimedia.org/wiki/Special:","https://commons.wikimedia.org/wiki/Special:")
    end
  end

  def date_display(date_time)
    begin
      I18n.l(Date.parse(date_time), format: :long)
    rescue
      ""
    end
   
  end

  def date_time_display(date_time)
    Time.zone = 'Eastern Time (US & Canada)'
    I18n.l(date_time.in_time_zone, format: :long)
  end

  def display_label(id)
    query = RDF::Query.new do
      pattern [RDF::URI(id), RDF::URI("http://www.w3.org/2000/01/rdf-schema#label"), :label]
    end
    query << RDF::Query::Pattern.new(RDF::URI(id), RDF::URI("http://schema.org/name"), :name, optional: true)
    solution = @production.graph.query(query)
    if solution.count > 0
      return solution.first[:label].value.capitalize
    else 
      return id
    end
  end

  def display_literal(literal)
    if literal["@language"]
      "#{literal['@value'].capitalize} @#{literal['@language']}" 
    elsif  literal["@value"]
      literal["@value"]
    else
      literal
    end
  end

  def display_reference(id)
    query = RDF::Query.new do
      pattern [RDF::URI(id), :p, :o]
    end
    @production.graph.query(query)
  end
end
