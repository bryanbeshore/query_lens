module QueryLens
  class SavedQuery < ApplicationRecord
    self.table_name = "query_lens_saved_queries"

    belongs_to :project, optional: true

    validates :name, presence: true
    validates :sql, presence: true
    validates :name, uniqueness: { scope: :project_id }

    default_scope { order(:position, :name) }
  end
end
