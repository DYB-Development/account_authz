# frozen_string_literal: true

class AddSentCountToInvitations < ActiveRecord::Migration[8.1]
  def change
    add_column :invitations, :sent_count, :integer, null: false, default: 1
  end
end
