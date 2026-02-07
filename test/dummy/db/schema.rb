ActiveRecord::Schema.define(version: 20260207000001) do
  create_table :users, force: true do |t|
    t.string :name
    t.string :email
    t.timestamps
  end

  create_table :accounts, force: true do |t|
    t.string :name
    t.string :plan
    t.timestamps
  end

  create_table :transactions, force: true do |t|
    t.references :account
    t.references :user
    t.decimal :amount, precision: 10, scale: 2
    t.string :description
    t.timestamps
  end

  create_table :query_lens_projects, force: true do |t|
    t.string :name, null: false
    t.text :description
    t.integer :position
    t.timestamps
  end

  add_index :query_lens_projects, :name, unique: true

  create_table :query_lens_saved_queries, force: true do |t|
    t.string :name, null: false
    t.text :description
    t.text :sql, null: false
    t.references :project, foreign_key: false
    t.integer :position
    t.timestamps
  end

  add_index :query_lens_saved_queries, [:project_id, :name], unique: true

  create_table :query_lens_conversations, force: true do |t|
    t.string :title, null: false
    t.text :messages
    t.text :last_sql
    t.timestamps
  end

  add_index :query_lens_conversations, :updated_at
end
