# class SearchController < ApplicationController

#   def index

#     @productions = Production.all
#     if params[:start].present? && params[:end].present?
#       date_range = [DateTime.parse(params[:start])..DateTime.parse(params[:end])]
#       @productions = @productions.where(date_of_first_performance: date_range)
#     end

#     if params[:data_source].present?
#       list_datasources = params[:data_source].split(",")
      

#       @productions = @productions.where(data_source_id: list_datasources)
#     end

#     if params[:query].present?
#       @productions = @productions.where('lower(label) LIKE :search OR lower(locality) LIKE :search OR lower(location_label) LIKE :search OR lower(country) LIKE :search', search: "%#{params[:query].downcase}%")
#     end

#     @productions = @productions.order(:date_of_first_performance).paginate(page: params[:page])
#   end
# end
