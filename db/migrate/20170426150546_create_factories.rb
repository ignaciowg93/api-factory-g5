class CreateFactories < ActiveRecord::Migration[5.0]

  def change
    create_table :factories do |t|
      t.integer :status
      t.boolean :busy

      t.timestamps
    end
  end
end
