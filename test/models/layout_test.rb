require 'test_helper'

class LayoutTest < ActiveSupport::TestCase
  setup do
    @layout = Layout.new
    @layout.add_field("http://example.com/0","zero")
  end

  test "add field one" do
    @layout.add_field("http://example.com/1","one")
    expected = [{"http://example.com/0"=>"zero", :direction=>"http://culture-in-time.org/ontology/Forward"}, {"http://example.com/1"=>"one", :direction=>"http://culture-in-time.org/ontology/Forward"}]
    assert_equal  expected, @layout.fields
  end

  test "move up and down" do
    @layout.add_field("http://example.com/1","one")
    @layout.move_up("http://example.com/1")
    expected = [{"http://example.com/1"=>"one", :direction=>"http://culture-in-time.org/ontology/Forward"}, {"http://example.com/0"=>"zero", :direction=>"http://culture-in-time.org/ontology/Forward"}]
    assert_equal  expected, @layout.fields
    @layout.move_down("http://example.com/1")
    expected = [{"http://example.com/0"=>"zero", :direction=>"http://culture-in-time.org/ontology/Forward"}, {"http://example.com/1"=>"one", :direction=>"http://culture-in-time.org/ontology/Forward"}]
    assert_equal  expected, @layout.fields
  end

  test "delete field one" do
    @layout.delete_field("http://example.com/0")
    expected = []
    assert_equal  expected, @layout.fields
  end

  test "make turtle" do
    expected = "<http://example.com/0>  <http://culture-in-time.org/ontology/order> 0 ; <http://culture-in-time.org/ontology/name> \"zero\" ; <http://culture-in-time.org/ontology/direction> <http://culture-in-time.org/ontology/Forward> .  rdfs:label <http://culture-in-time.org/ontology/order> \"99\"^^xsd:integer ."  
    assert_equal  expected, @layout.turtle
  end

  test "add direction reverse" do
    @layout.add_field("http://example.com/1","one","Reverse")
    expected = [{"http://example.com/0"=>"zero", :direction=>"http://culture-in-time.org/ontology/Forward"}, {"http://example.com/1"=>"one", :direction=>"http://culture-in-time.org/ontology/Reverse"}]
    assert_equal  expected, @layout.fields
  end

  test "add direction reverse and move up" do
    @layout.add_field("http://example.com/1","one","Reverse")
    @layout.move_up("http://example.com/1")
    expected = [{"http://example.com/1"=>"one", :direction=>"http://culture-in-time.org/ontology/Reverse"}, {"http://example.com/0"=>"zero", :direction=>"http://culture-in-time.org/ontology/Forward"}]
    assert_equal  expected, @layout.fields
  end

  test "make turtle with direction" do
    @layout.delete_field("http://example.com/0")
    @layout.add_field("http://example.com/1","one","Reverse")
    expected = "<http://example.com/1>  <http://culture-in-time.org/ontology/order> 0 ; <http://culture-in-time.org/ontology/name> \"one\" ; <http://culture-in-time.org/ontology/direction> <http://culture-in-time.org/ontology/Reverse> .  rdfs:label <http://culture-in-time.org/ontology/order> \"99\"^^xsd:integer ."  
    assert_equal  expected, @layout.turtle
  end
end