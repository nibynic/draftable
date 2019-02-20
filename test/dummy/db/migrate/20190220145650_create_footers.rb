class CreateFooters < ActiveRecord::Migration[5.2]
  def change
    create_table :footers do |t|
      t.text :content
      t.references :post, foreign_key: true

      t.timestamps
    end
  end
end
