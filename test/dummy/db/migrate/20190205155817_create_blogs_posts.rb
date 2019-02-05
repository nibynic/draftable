class CreateBlogsPosts < ActiveRecord::Migration[5.2]
  def change
    create_table :blogs_posts, id: false do |t|
      t.references :blog, foreign_key: true
      t.references :post, foreign_key: true
    end
  end
end
