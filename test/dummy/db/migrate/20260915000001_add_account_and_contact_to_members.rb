# frozen_string_literal: true

class AddAccountAndContactToMembers < ActiveRecord::Migration[8.1]
  def change
    add_column :members, :account_id, :bigint
    add_column :members, :name, :string
    add_column :members, :email, :string
  end
end
