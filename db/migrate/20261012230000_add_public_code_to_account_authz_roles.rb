class AddPublicCodeToAccountAuthzRoles < ActiveRecord::Migration[8.1]
  class Record < ActiveRecord::Base
    self.table_name = "account_authz_roles"
  end

  def up
    add_column :account_authz_roles, :public_code, :string
    Record.reset_column_information
    Record.find_each { |record| record.update_columns(public_code: PublicCode.generate) }
    change_column_null :account_authz_roles, :public_code, false
    add_index :account_authz_roles, :public_code, unique: true
  end

  def down
    remove_column :account_authz_roles, :public_code
  end
end
