Rails.application.routes.draw do
  resources :materiels
  get '/materiels/traces/(:id)', to: 'materiels#index_trace', as: 'materiels_traces'
  resources :randonnees, :treks
  get '/randonnees/page/(:idpage)', to: 'randonnees#index', as: 'randonnees_page'
  get '/randonnees/trek/(:id)/page/(:idpage)', to: 'randonnees#trek_index', as: 'randonnees_trek_page'
  get '/treks/page/(:idpage)', to: 'treks#index', as: 'treks_page'
  post 'uploadimage', to: 'application#upload_image'
  get '/admin', to: 'admin#password'
  get '/apropos', to: 'treks#a_propos'
  get '/agenda', to: 'application#agenda'
  post '/admin', to: 'admin#check_password'
  root to: 'application#index'
  get '/agenda/edit', to: 'application#agenda_edit'
  post '/agenda', to: 'application#agenda_update'
  get '/photos_number/(:rep)', to: 'traces#photos_number', as: 'photos_number'
  get '/maj', to: 'admin#maj_polylines'
end
