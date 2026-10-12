# frozen_string_literal: true

require "test_helper"
require "public_code/test_help"

class TeamCodedAddressesTest < ActionView::TestCase
  helper KeystoneUiHelper

  setup do
    AccountAuthz.reset!
    AccountAuthz.catalog { permission :manage_members }
    @was = AccountAuthz.members_source
    AccountAuthz.members_source = CodedMemberDirectory
    @manager = ::Member.create!(account_id: 1, name: "Pretend Manager")
    @manager.assign_role(AccountAuthz::Role.create!(account_id: 1, name: "Manager", capabilities: %w[manage_members], rank: 2))
    @person = CodedMember.create!(account_id: 1, name: "Pretend Person", email: "pretend@example.com")
    @person.assign_role(AccountAuthz::Role.create!(account_id: 1, name: "Editor", capabilities: [], rank: 0))
    AccountAuthz::Role.create!(account_id: 1, name: "Viewer", capabilities: [], rank: 0)
    CodedInvitation.create!(account_id: 1, name: "Invited Person", email: "invited@example.com")
  end

  teardown do
    AccountAuthz.members_source = @was
    AccountAuthz.reset!
  end

  test "the team section links to no numbered address" do
    render partial: "account_authz/members/team", locals: {
      person: @manager, account: 1, selection: { member_id: @person.to_param },
      submit_urls: { invite: "/here/invite", resend: "/here/resend", cancel: "/here/cancel",
                    give_role: "/here/give", take_role: "/here/take", remove: "/here/remove" }
    }

    assert_empty PublicCode::TestHelp.numbered_links(addresses_sent)
  end

  private

  def addresses_sent
    links = css_select("a[href]").map { |link| "/settings#{link['href']}" }
    fields = css_select("form input[type=hidden]:not([name=_method]):not([name=authenticity_token])").map { |field| "#{field.ancestors('form').first['action']}?#{field['name']}=#{field['value']}" }
    links + fields
  end
end
