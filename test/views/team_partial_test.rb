# frozen_string_literal: true

require "test_helper"

class TeamPartialTest < ActionView::TestCase
  helper KeystoneUiHelper

  setup do
    AccountAuthz.reset!
    AccountAuthz.catalog { permission :manage_members }
    @manager = ::Member.create!(account_id: 1, name: "Pretend Manager")
    @manager.assign_role(AccountAuthz::Role.create!(account_id: 1, name: "Manager", capabilities: %w[manage_members], rank: 2))
    ::Member.create!(account_id: 1, name: "Pretend Person", email: "pretend@example.com")
  end

  teardown { AccountAuthz.reset! }

  test "the team partial lists the people in the account it is given" do
    render partial: "account_authz/members/team", locals: {
      person: @manager, account: 1, selection: {},
      submit_urls: { invite: "/here/invite", resend: "/here/resend", cancel: "/here/cancel" }
    }

    assert_includes rendered, "Pretend Person"
  end

  test "each form submits to the address it was given" do
    render partial: "account_authz/members/team", locals: {
      person: @manager, account: 1, selection: {},
      submit_urls: { invite: "/here/invite", resend: "/here/resend", cancel: "/here/cancel" }
    }

    assert_includes rendered, 'action="/here/invite"'
  end

  test "the team partial draws no page heading of its own" do
    render partial: "account_authz/members/team", locals: {
      person: @manager, account: 1, selection: {},
      submit_urls: { invite: "/here/invite", resend: "/here/resend", cancel: "/here/cancel" }
    }

    assert_no_match(/<h1/, rendered)
  end

  test "asking for one person shows the roles they hold" do
    person = ::Member.create!(account_id: 1, name: "Pretend Person", email: "pretend@example.com")
    role = AccountAuthz::Role.create!(account_id: 1, name: "Editor", capabilities: [], rank: 0)
    person.assign_role(role)

    render partial: "account_authz/members/team", locals: {
      person: @manager, account: 1, selection: { member_id: person.id.to_s },
      submit_urls: { invite: "/here/invite", resend: "/here/resend", cancel: "/here/cancel",
                    give_role: "/here/give", take_role: "/here/take", remove: "/here/remove" }
    }

    assert_includes rendered, 'action="/here/take"'
  end

  test "the team section takes a role by its code" do
    person = ::Member.create!(account_id: 1, name: "Pretend Person", email: "pretend@example.com")
    role = AccountAuthz::Role.create!(account_id: 1, name: "Editor", capabilities: [], rank: 0)
    person.assign_role(role)

    render partial: "account_authz/members/team", locals: {
      person: @manager, account: 1, selection: { member_id: person.id.to_s },
      submit_urls: { invite: "/here/invite", resend: "/here/resend", cancel: "/here/cancel",
                    give_role: "/here/give", take_role: "/here/take", remove: "/here/remove" }
    }

    assert_select "form[action='/here/take'] input[name=role_id][value=?]", role.public_code
  end

  test "the team section gives a role by its code" do
    person = ::Member.create!(account_id: 1, name: "Pretend Person", email: "pretend@example.com")
    role = AccountAuthz::Role.create!(account_id: 1, name: "Editor", capabilities: [], rank: 0)

    render partial: "account_authz/members/team", locals: {
      person: @manager, account: 1, selection: { member_id: person.id.to_s },
      submit_urls: { invite: "/here/invite", resend: "/here/resend", cancel: "/here/cancel",
                    give_role: "/here/give", take_role: "/here/take", remove: "/here/remove" }
    }

    assert_select "form[action='/here/give'] input[name=role_id][value=?]", role.public_code
  end

  test "each row leads to that person" do
    person = ::Member.create!(account_id: 1, name: "Pretend Person", email: "pretend@example.com")

    render partial: "account_authz/members/team", locals: {
      person: @manager, account: 1, selection: {},
      submit_urls: { invite: "/here/invite", resend: "/here/resend", cancel: "/here/cancel" }
    }

    assert_includes rendered, "?member_id=#{person.id}"
  end

  test "asking for someone who is not in the account shows no person" do
    render partial: "account_authz/members/team", locals: {
      person: @manager, account: 1, selection: { member_id: "999999" },
      submit_urls: { invite: "/here/invite", resend: "/here/resend", cancel: "/here/cancel",
                    give_role: "/here/give", take_role: "/here/take", remove: "/here/remove" }
    }

    assert_not_includes rendered, 'action="/here/take"'
  end

  test "the team section asks a source that answers the member lookup for the chosen member" do
    person = ::Member.create!(account_id: 1, name: "Chosen Person", email: "chosen@example.com")
    source = Class.new(MemberDirectory) do
      define_singleton_method(:member) { |account_id, address| address == "pretend-code" ? members(account_id).find(person.id) : raise(ActiveRecord::RecordNotFound) }
    end
    was = AccountAuthz.members_source
    AccountAuthz.members_source = source

    begin
      render partial: "account_authz/members/team", locals: {
        person: @manager, account: 1, selection: { member_id: "pretend-code" },
        submit_urls: { invite: "/here/invite", resend: "/here/resend", cancel: "/here/cancel",
                      give_role: "/here/give", take_role: "/here/take", remove: "/here/remove" }
      }
    ensure
      AccountAuthz.members_source = was
    end

    assert_select "h2.ks-section-title", text: "Chosen Person"
  end

  test "each row leads to that person by the address the person gives" do
    person = ::Member.create!(account_id: 1, name: "Coded Person", email: "coded@example.com")
    person.define_singleton_method(:to_param) { "pretend-code" }
    source = Class.new(MemberDirectory) do
      define_singleton_method(:members) { |_account_id| [ person ] }
    end
    was = AccountAuthz.members_source
    AccountAuthz.members_source = source

    begin
      render partial: "account_authz/members/team", locals: {
        person: @manager, account: 1, selection: {},
        submit_urls: { invite: "/here/invite", resend: "/here/resend", cancel: "/here/cancel" }
      }
    ensure
      AccountAuthz.members_source = was
    end

    assert_includes rendered, "?member_id=pretend-code"
  end

  test "removing the chosen person sends the address the person gives" do
    render_team_for_coded_person

    assert_select "form[action='/here/remove'] input[name=member_id][value=pretend-code]"
  end

  test "giving the chosen person a role sends the address the person gives" do
    AccountAuthz::Role.create!(account_id: 1, name: "Editor", capabilities: [], rank: 0)

    render_team_for_coded_person

    assert_select "form[action='/here/give'] input[name=member_id][value=pretend-code]"
  end

  test "taking a role from the chosen person sends the address the person gives" do
    render_team_for_coded_person(holding: AccountAuthz::Role.create!(account_id: 1, name: "Editor", capabilities: [], rank: 0))

    assert_select "form[action='/here/take'] input[name=member_id][value=pretend-code]"
  end

  test "sending an invitation again sends the address the invitation gives" do
    render_team_with_tokened_invitation

    assert_select "form[action='/here/resend'] input[name=invitation_id][value=pretend-token]"
  end

  private

  def render_team_for_coded_person(holding: nil)
    person = ::Member.create!(account_id: 1, name: "Coded Person", email: "coded@example.com")
    person.assign_role(holding) if holding
    person.define_singleton_method(:to_param) { "pretend-code" }
    source = Class.new(MemberDirectory) do
      define_singleton_method(:member) { |_account_id, address| address == "pretend-code" ? person : raise(ActiveRecord::RecordNotFound) }
    end
    was = AccountAuthz.members_source
    AccountAuthz.members_source = source

    begin
      render partial: "account_authz/members/team", locals: {
        person: @manager, account: 1, selection: { member_id: "pretend-code" },
        submit_urls: { invite: "/here/invite", resend: "/here/resend", cancel: "/here/cancel",
                      give_role: "/here/give", take_role: "/here/take", remove: "/here/remove" }
      }
    ensure
      AccountAuthz.members_source = was
    end
  end

  def render_team_with_tokened_invitation
    invitation = ::Invitation.create!(account_id: 1, name: "Invited Person", email: "invited@example.com")
    invitation.define_singleton_method(:to_param) { "pretend-token" }
    source = Class.new(MemberDirectory) do
      define_singleton_method(:invitations) { |_account_id| [ invitation ] }
    end
    was = AccountAuthz.members_source
    AccountAuthz.members_source = source

    begin
      render partial: "account_authz/members/team", locals: {
        person: @manager, account: 1, selection: {},
        submit_urls: { invite: "/here/invite", resend: "/here/resend", cancel: "/here/cancel" }
      }
    ensure
      AccountAuthz.members_source = was
    end
  end
end
