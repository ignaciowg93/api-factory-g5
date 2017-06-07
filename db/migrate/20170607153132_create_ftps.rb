class CreateFtps < ActiveRecord::Migration[5.0]
  def change
    create_table :ftps do |t|

      t.timestamps
    end
  end
end
