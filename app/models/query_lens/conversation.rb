module QueryLens
  class Conversation < ApplicationRecord
    self.table_name = "query_lens_conversations"

    serialize :messages, coder: JSON

    validates :title, presence: true
    validates :messages, presence: true

    default_scope { order(updated_at: :desc) }

    def self.title_from_message(content)
      content.to_s.truncate(80)
    end
  end
end
