# frozen_string_literal: true

class AddRankToCitizenRoles < ActiveRecord::Migration[8.1]
  def change
    add_column :citizen_roles, :rank, :integer, null: false, default: 0
  end
end
