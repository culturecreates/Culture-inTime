# Layout used in a Spotlight
class Layout
  attr_accessor :turtle, :fields

  def initialize(turtle = "") 
    @turtle = turtle
    @fields = turtle_to_list(turtle)
  end

  def turtle_to_list(turtle)
    graph = RDF::Graph.new
    graph.from_ttl(turtle, prefixes: {rdf: RDF.to_uri, cit: "<http://culture-in-time.org/ontology/>"})

    # cit = RDF::Vocabulary.new("http://culture-in-time.org/ontology/")
    query = RDF::Query.new do 
      pattern [:uri,RDF::URI("http://culture-in-time.org/ontology/name"), :name]
      pattern [:uri, RDF::URI("http://culture-in-time.org/ontology/order"), :order]
    end
    query << RDF::Query::Pattern.new(:uri, RDF::URI("http://culture-in-time.org/ontology/direction"), :direction, optional: true)
    fields = []
    query.execute(graph) do |solution| 
      if solution.to_h[:direction] 
        fields << { solution.uri.value => solution.name.value, order:  solution.order.value.to_i, direction: solution.direction.value}
      else
        fields << { solution.uri.value => solution.name.value, order:  solution.order.value.to_i, direction: "http://culture-in-time.org/ontology/Forward"}
      end
    end
    fields.sort_by! { |f| f[:order] }
    puts "fields converted from turtle to list: #{fields}"
    fields
  end


  def add_field(uri, name, direction = nil)
    return false if @fields.select {|f| f.has_key?(uri)}.present?
    if direction == "Reverse"
      @fields << { uri =>  name, direction: "http://culture-in-time.org/ontology/Reverse"}
    else
      @fields << { uri =>  name, direction: "http://culture-in-time.org/ontology/Forward"}
    end
    true
  end

  def delete_field(uri)
    initial_length = @fields.length
    @fields.delete_if{|f| f.first[0] == uri }
    current_length = @fields.length
    if initial_length == current_length
      return false
    else
      return true
    end
  end

  def move_up(uri)
    index = @fields.index { |f| f.first[0] == uri } 
    if index > 0
      obj = @fields.delete_at(index)
      @fields.insert(index - 1,obj)
    end
  end


  def move_down(uri)
    index = @fields.index { |f| f.first[0] == uri } 
    if index
      obj = @fields.delete_at(index)
      @fields.insert(index + 1,obj)
    end
  end

  def turtle
    turtle = ''
    puts "converting to turtle: #{@fields}"
    @fields.each_with_index do |field,index|
      uri = field.first[0]
      name = field.first[1]
      turtle += "<#{uri}>  <http://culture-in-time.org/ontology/order> #{index} ; <http://culture-in-time.org/ontology/name> \"#{name}\" ; <http://culture-in-time.org/ontology/direction> <#{field[:direction]}> .  "
     
    end
    turtle
  end


end