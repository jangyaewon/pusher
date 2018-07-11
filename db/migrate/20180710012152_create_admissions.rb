class CreateAdmissions < ActiveRecord::Migration[5.0]
  def change
    create_table :admissions do |t|
      t.references    :user
      t.references    :chat_room
      
      t.timestamps
    end
  end
end
