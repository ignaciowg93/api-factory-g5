class AddTokenToClients < ActiveRecord::Migration[5.0]
  def change
    add_column :clients, :token, :string
  end
end
