# frozen_string_literal: true

require 'resque/server'

Rails.application.routes.draw do
  get 'metrics', to: 'internal#metrics'
  get 'healthz', to: 'internal#healthz'
  mount Resque::Server, at: '/q'
  resources :log_entries
  resources :messages

  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
end
