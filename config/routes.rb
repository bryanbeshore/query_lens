QueryLens::Engine.routes.draw do
  root to: "queries#show"

  post "execute", to: "queries#execute"
  post "generate", to: "ai#generate"
end
