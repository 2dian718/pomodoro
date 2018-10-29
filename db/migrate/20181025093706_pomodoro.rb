class Pomodoro < ActiveRecord::Migration[5.2]
  def change
    create_table :pomodoros do |t|
      t.string :name
      t.string :vchannel_id
      t.string :sender
      t.datetime :ended_at
      t.integer :state, default: 0
      t.references :app, index: true, polymorphic: true

      t.timestamps
    end
  end
end
