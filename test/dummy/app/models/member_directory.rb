# frozen_string_literal: true

class MemberDirectory
  def self.members(account_id)
    Member.where(account_id: account_id)
  end
end
