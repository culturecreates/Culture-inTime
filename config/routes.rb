Rails.application.routes.draw do
  resources :people
  resources :works
  resources :spotlights
  resources :places
  resources :organizations
  root 'home#index'
  get '/search', to: 'search#index'

  get '/spotlight', to: 'home#spotlight'

  get '/admin', to: 'admin#index', as: 'admin'

  get '/admin/build_cache', to: 'admin#build_cache', as: 'admin_build_cache'
 

  resources :productions
  resources :data_sources do
    member do
      get 'load'
    end
    
  end
  
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
