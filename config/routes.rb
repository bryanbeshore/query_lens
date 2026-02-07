QueryLens::Engine.routes.draw do
  root to: "queries#show"

  get "info", to: "queries#info"
  post "execute", to: "queries#execute"
  post "generate", to: "ai#generate"

  resources :projects, only: [:index, :create, :update, :destroy]
  resources :saved_queries, only: [:create, :update, :destroy]
  resources :conversations, only: [:index, :show, :create, :update, :destroy]
end
