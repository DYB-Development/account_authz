# frozen_string_literal: true

class MemberDirectory
  def self.members(account_id)
    Member.where(account_id: account_id)
  end

  def self.invite(account_id:, name:, email:, invited_by:)
    Member.create!(account_id: account_id, name: name, email: email)
  end

  def self.remove(member)
    member.destroy!
  end
end
