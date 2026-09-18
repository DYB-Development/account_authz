# frozen_string_literal: true

require "test_helper"

module Citizen
  class ActingMemberTest < ActiveSupport::TestCase
    test "a source that knows how to find the membership is asked" do
      source = Class.new do
        def self.member_for(account_id:, person:) = "the membership of #{person} in #{account_id}"
      end

      assert_equal "the membership of someone in 1", ActingMember.for(person: "someone", account: 1, source: source)
    end

    test "a source that does not know is left alone and the person stands in" do
      source = Class.new

      assert_equal "someone", ActingMember.for(person: "someone", account: 1, source: source)
    end
  end
end
