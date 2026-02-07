module QueryLens
  class Project < ApplicationRecord
    self.table_name = "query_lens_projects"

    has_many :saved_queries, dependent: :nullify

    validates :name, presence: true, uniqueness: true

    default_scope { order(:position, :name) }
  end
end
