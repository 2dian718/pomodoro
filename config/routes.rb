Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  post '/bearychat', to: 'pomodoro_apps#message', as: :beary_message
end
