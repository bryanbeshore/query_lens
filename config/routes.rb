QueryLens::Engine.routes.draw do
  root to: "queries#show"

  get "info", to: "queries#info"
  post "execute", to: "queries#execute"
  post "generate", to: "ai#generate"
end
