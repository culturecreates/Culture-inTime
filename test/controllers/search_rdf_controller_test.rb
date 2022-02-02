require 'test_helper'

class SearchRdfControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get search_rdf_index_url
    assert_response :success
  end

end
