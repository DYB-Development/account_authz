# frozen_string_literal: true

class CodedMember < ApplicationRecord
  include AccountAuthz::Member
  has_public_code
end
