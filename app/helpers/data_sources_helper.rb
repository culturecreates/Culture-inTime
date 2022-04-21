module DataSourcesHelper


  def time_estimate(data_source)
    estimate = data_source.uri_count.to_i * 0.005 * data_source.sample_graph.lines.count 
    distance_of_time_in_words(Time.now,estimate.seconds.from_now )
  end

end
