$LOAD_PATH.unshift 'lib'
require 'vendorer'
require 'vendorer/version'
require 'rspec/mocks'

RSpec.configure do |config|
  config.expect_with(:rspec) { |c| c.syntax = :should }
end
