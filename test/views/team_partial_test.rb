# frozen_string_literal: true

require "test_helper"

class TeamPartialTest < ActionView::TestCase
  helper KeystoneUiHelper

  setup do
    Citizen.reset!
    Citizen.catalog { permission :manage_members }
    @manager = ::Member.create!(account_id: 1, name: "Pretend Manager")
    @manager.assign_role(Citizen::Role.create!(account_id: 1, name: "Manager", capabilities: %w[manage_members], rank: 2))
    ::Member.create!(account_id: 1, name: "Pretend Person", email: "pretend@example.com")
  end

  teardown { Citizen.reset! }

  test "the team partial lists the people in the account it is given" do
    render partial: "citizen/members/team", locals: {
      person: @manager, account: 1, selection: {},
      submit_urls: { invite: "/here/invite", resend: "/here/resend", cancel: "/here/cancel" }
    }

    assert_includes rendered, "Pretend Person"
  end

  test "each form submits to the address it was given" do
    render partial: "citizen/members/team", locals: {
      person: @manager, account: 1, selection: {},
      submit_urls: { invite: "/here/invite", resend: "/here/resend", cancel: "/here/cancel" }
    }

    assert_includes rendered, 'action="/here/invite"'
  end

  test "the team partial draws no page heading of its own" do
    render partial: "citizen/members/team", locals: {
      person: @manager, account: 1, selection: {},
      submit_urls: { invite: "/here/invite", resend: "/here/resend", cancel: "/here/cancel" }
    }

    assert_no_match(/<h1/, rendered)
  end

  test "asking for one person shows the roles they hold" do
    person = ::Member.create!(account_id: 1, name: "Pretend Person", email: "pretend@example.com")
    role = Citizen::Role.create!(account_id: 1, name: "Editor", capabilities: [], rank: 0)
    person.assign_role(role)

    render partial: "citizen/members/team", locals: {
      person: @manager, account: 1, selection: { member_id: person.id.to_s },
      submit_urls: { invite: "/here/invite", resend: "/here/resend", cancel: "/here/cancel",
                    give_role: "/here/give", take_role: "/here/take", remove: "/here/remove" }
    }

    assert_includes rendered, 'action="/here/take"'
  end

  test "each row leads to that person" do
    person = ::Member.create!(account_id: 1, name: "Pretend Person", email: "pretend@example.com")

    render partial: "citizen/members/team", locals: {
      person: @manager, account: 1, selection: {},
      submit_urls: { invite: "/here/invite", resend: "/here/resend", cancel: "/here/cancel" }
    }

    assert_includes rendered, "?member_id=#{person.id}"
  end

  test "asking for someone who is not in the account shows no person" do
    render partial: "citizen/members/team", locals: {
      person: @manager, account: 1, selection: { member_id: "999999" },
      submit_urls: { invite: "/here/invite", resend: "/here/resend", cancel: "/here/cancel",
                    give_role: "/here/give", take_role: "/here/take", remove: "/here/remove" }
    }

    assert_not_includes rendered, 'action="/here/take"'
  end
end
