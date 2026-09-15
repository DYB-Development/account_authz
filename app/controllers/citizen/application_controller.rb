module Citizen
  class ApplicationController < ::ApplicationController
    include Citizen::Authorization

    helper Citizen::AppRoutesHelper, KeystoneUiHelper
  end
end
