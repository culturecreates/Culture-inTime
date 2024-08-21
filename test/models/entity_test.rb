require 'test_helper'

class EntityTest < ActiveSupport::TestCase
  test "framing" do
    entity = Entity.new
    entity.entity_uri = "http://www.wikidata.org/entity/Q110835489"
    entity.graph
    expected = 22
    assert_equal  expected, entity.spotlight_properties.count
  end

  test "demo" do
    entity = Entity.new
    expected = {"@context"=>{"@base"=>"http://www.artsdata.ca/resource/", "@vocab"=>"http://www.artsdata.ca/resource/"}, "@id"=>"TheShow", "@type"=>"Performance", "performer"=>{"@id"=>"John", "@type"=>"Person", "name"=>"John Smith"}}
    assert_equal  expected, entity.test_frame
  end
end