# frozen_string_literal: true

require "test_helper"
require "public_code/test_help"

module AccountAuthz
  class CodedAddressesTest < ActionDispatch::IntegrationTest
    include PublicCode::TestHelp

    setup do
      AccountAuthz.reset!
      AccountAuthz.catalog do
        permission :manage_members
        permission :manage_roles
      end
      @was = AccountAuthz.members_source
      AccountAuthz.members_source = CodedMemberDirectory
      @manager = ::Member.create!(account_id: 1, name: "Pretend Manager")
      @manager.assign_role(Role.create!(account_id: 1, name: "Manager", capabilities: %w[manage_members manage_roles], rank: 2))
      @person = CodedMember.create!(account_id: 1, name: "Pretend Person", email: "pretend@example.com")
      @role = Role.create!(account_id: 1, name: "Editor", capabilities: [], rank: 0)
      @person.assign_role(@role)
      CodedInvitation.create!(account_id: 1, name: "Invited Person", email: "invited@example.com")
    end

    teardown do
      AccountAuthz.members_source = @was
      AccountAuthz.reset!
    end

    test "the members pages link to no numbered address" do
      assert_no_numbered_links([ signed_in("/account_authz/members"), signed_in("/account_authz/members/#{@person.to_param}") ])
    end

    test "the roles pages link to no numbered address" do
      assert_no_numbered_links([ signed_in("/account_authz/roles"), signed_in("/account_authz/roles/#{@role.to_param}/edit") ])
    end

    private

    def signed_in(path) = "#{path}?signed_in_member_id=#{@manager.id}&account_id=1"
  end
end
