json.extract! spotlight, :id, :title, :subtitle, :image, :description, :location, :start_date, :end_date, :query, :created_at, :updated_at
json.url spotlight_url(spotlight, format: :json)
json.downloadUrl "wikidataJSON" =>  download_spotlight_url(spotlight, format: :json), "RDFstarJSON" => nil