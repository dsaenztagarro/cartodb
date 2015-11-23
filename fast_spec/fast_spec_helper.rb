# Load required files from the app
#
#   app_require 'app/model/profile'
#
def app_require(file)
  require File.expand_path(file)
end
