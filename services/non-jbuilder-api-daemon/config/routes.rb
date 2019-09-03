# frozen_string_literal: true

Rails.application.routes.draw do
  get 'metrics', to: 'internal#metrics'
  get 'healthz', to: 'internal#healthz'
  resources :log_entries, path: :logs
  resources :messages
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
end
