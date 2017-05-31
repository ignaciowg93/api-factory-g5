class CreateSellers < ActiveRecord::Migration[5.0]
  def change
    create_table :sellers do |t|
      t.references :supply, foreign_key: true
      t.string :seller
      t.decimal :time

      t.timestamps
    end
  end
end
