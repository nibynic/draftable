class CreateHeaders < ActiveRecord::Migration[5.2]
  def change
    create_table :headers do |t|
      t.text :content
      t.references :post, foreign_key: true

      t.timestamps
    end
  end
end
