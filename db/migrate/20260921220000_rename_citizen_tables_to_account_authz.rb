class RenameCitizenTablesToAccountAuthz < ActiveRecord::Migration[8.1]
  def change
    rename_table :citizen_roles, :account_authz_roles
    rename_table :citizen_assignments, :account_authz_assignments
    rename_index :account_authz_assignments,
      "index_citizen_assignments_unique",
      "index_account_authz_assignments_unique"
  end
end
