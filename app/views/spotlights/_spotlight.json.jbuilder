json.extract! spotlight, :id, :title, :subtitle, :image, :description, :location, :start_date, :end_date, :query, :created_at, :updated_at
json.url spotlight_url(spotlight, format: :json)
json.refreshFrequency nil
json.downloadUrl "wikidataJSON" =>  nil, "RDFstarJSON" => nil