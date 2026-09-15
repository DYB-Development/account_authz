# frozen_string_literal: true

Citizen.members_source = ->(account_id) { Member.where(account_id: account_id) }
