class AddColorToGoals < ActiveRecord::Migration[8.1]
  def change
    add_column :goals, :color, :string
  end
end
