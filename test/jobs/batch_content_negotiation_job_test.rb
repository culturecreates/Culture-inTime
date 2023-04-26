require 'test_helper'

class BatchContentNegotiationJobTest < ActiveJob::TestCase

  test "job" do 
    BatchContentNegotiationJob.perform_now("http://www.wikidata.org/entity/Q47401546")
  end


end
