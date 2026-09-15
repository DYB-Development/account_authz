module Citizen
  class ApplicationController < ::ApplicationController
    include Citizen::Authorization

    helper Citizen::AppRoutesHelper
  end
end
