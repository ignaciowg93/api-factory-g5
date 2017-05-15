class AddGnumberToClients < ActiveRecord::Migration[5.0]
  def change
    add_column :clients, :gnumber, :string
  end
end
