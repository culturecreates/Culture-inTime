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

    cit = RDF::Vocabulary.new("http://culture-in-time.org/ontology/")
    query = RDF::Query.new({
      uri: {
        cit.name => :name,
        cit.order => :order,
      }
    }, **{})
    
    fields = []
    query.execute(graph) do |solution|
      fields << {solution.uri.value => solution.name.value, order:  solution.order.value.to_i }
    end
    fields.sort_by! { |f| f[:order] }
    # puts "fields: #{fields}"
    fields
  end


  def add_field(uri, name)
    return false if @fields.select {|f| f.has_key?(uri)}.present?
    @fields << { uri =>  name }
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
    @fields.each_with_index do |field,index|
      turtle += "<#{field.first[0]}>  <http://culture-in-time.org/ontology/order> #{index} ; <http://culture-in-time.org/ontology/name> \"#{field.first[1]}\" .  "
    end
    turtle
  end


end