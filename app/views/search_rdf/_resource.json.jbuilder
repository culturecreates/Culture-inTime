json.extract! resource, :entity_uri, :title, :date_of_first_performance, :description, :location_label 
json.image  production_image(resource)
json.url   request.protocol + request.host_with_port + productions_show_path(uri: resource.entity_uri, layout: @spotlight, format: :json)