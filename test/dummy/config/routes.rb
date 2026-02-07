Rails.application.routes.draw do
  mount QueryLens::Engine => "/query_lens"
end
