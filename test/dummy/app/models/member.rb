# frozen_string_literal: true

class Member < ApplicationRecord
  include AccountAuthz::Member
end
