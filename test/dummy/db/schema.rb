ActiveRecord::Schema.define(version: 1) do
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
end
