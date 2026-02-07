class CreateQueryLensTables < ActiveRecord::Migration[7.1]
  def change
    create_table :query_lens_projects do |t|
      t.string :name, null: false
      t.text :description
      t.integer :position
      t.timestamps
    end

    add_index :query_lens_projects, :name, unique: true

    create_table :query_lens_saved_queries do |t|
      t.string :name, null: false
      t.text :description
      t.text :sql, null: false
      t.references :project, foreign_key: { to_table: :query_lens_projects, on_delete: :nullify }
      t.integer :position
      t.timestamps
    end

    add_index :query_lens_saved_queries, [:project_id, :name], unique: true
  end
end
