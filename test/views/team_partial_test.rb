# frozen_string_literal: true

require "test_helper"

class TeamPartialTest < ActionView::TestCase
  helper KeystoneUiHelper

  setup do
    Citizen.reset!
    Citizen.catalog { permission :manage_members }
    @manager = ::Member.create!(account_id: 1, name: "Pretend Manager")
    ::Member.create!(account_id: 1, name: "Pretend Person", email: "pretend@example.com")
  end

  teardown { Citizen.reset! }

  test "the team partial lists the people in the account it is given" do
    render partial: "citizen/members/team", locals: {
      person: @manager, account: 1,
      submit_urls: { invite: "/here/invite", resend: "/here/resend", cancel: "/here/cancel" }
    }

    assert_includes rendered, "Pretend Person"
  end

  test "each form submits to the address it was given" do
    render partial: "citizen/members/team", locals: {
      person: @manager, account: 1,
      submit_urls: { invite: "/here/invite", resend: "/here/resend", cancel: "/here/cancel" }
    }

    assert_includes rendered, 'action="/here/invite"'
  end

  test "the team partial draws no page heading of its own" do
    render partial: "citizen/members/team", locals: {
      person: @manager, account: 1,
      submit_urls: { invite: "/here/invite", resend: "/here/resend", cancel: "/here/cancel" }
    }

    assert_no_match(/<h1/, rendered)
  end
end
