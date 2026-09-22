# frozen_string_literal: true

module AccountAuthz
  class Assignment < ApplicationRecord
    belongs_to :member, polymorphic: true
    belongs_to :role, class_name: "AccountAuthz::Role"
  end
end
