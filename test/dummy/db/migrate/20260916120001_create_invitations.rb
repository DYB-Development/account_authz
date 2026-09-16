# frozen_string_literal: true

class CreateInvitations < ActiveRecord::Migration[8.1]
  def change
    create_table :invitations do |t|
      t.bigint :account_id, null: false
      t.string :name, null: false
      t.string :email, null: false

      t.timestamps
    end
  end
end
