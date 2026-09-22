# frozen_string_literal: true

Rails.application.config.to_prepare do
  AccountAuthz.members_source = MemberDirectory
end
