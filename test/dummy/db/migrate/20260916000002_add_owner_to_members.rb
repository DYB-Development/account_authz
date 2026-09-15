# frozen_string_literal: true

class AddOwnerToMembers < ActiveRecord::Migration[8.1]
  def change
    add_column :members, :owner, :boolean, null: false, default: false
  end
end
