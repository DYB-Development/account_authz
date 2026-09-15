module Citizen
  class ApplicationController < ::ApplicationController
    include Citizen::Authorization
  end
end
