class RenameCitizenMemberIndex < ActiveRecord::Migration[8.1]
  def change
    rename_index :account_authz_assignments,
      "index_citizen_assignments_on_member",
      "index_account_authz_assignments_on_member"
  end
end
