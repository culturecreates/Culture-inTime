require 'test_helper'

class RDFGraphTest < ActionView::TestCase
  
  test "generate SPARQL" do
    data_source = data_sources(:one)
   
   
    assert !RDFGraph.generate_sparql(data_source).include?("placeholder")
   
  end

end
