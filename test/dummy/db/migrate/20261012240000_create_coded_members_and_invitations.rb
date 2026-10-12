# frozen_string_literal: true

class CreateCodedMembersAndInvitations < ActiveRecord::Migration[8.1]
  def change
    create_table :coded_members do |t|
      t.bigint :account_id
      t.string :name
      t.string :email
      t.boolean :owner, null: false, default: false
      t.string :public_code, null: false, index: { unique: true }

      t.timestamps
    end

    create_table :coded_invitations do |t|
      t.bigint :account_id, null: false
      t.string :name, null: false
      t.string :email, null: false
      t.integer :sent_count, null: false, default: 1
      t.string :public_code, null: false, index: { unique: true }

      t.timestamps
    end
  end
end
