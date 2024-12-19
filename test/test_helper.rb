# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "cal_invite"
require "minitest/autorun"

# Configure SimpleCov
require "simplecov"
SimpleCov.start do
  add_filter "/test/"
  enable_coverage :branch
end

# Reset configuration before tests
CalInvite.reset_configuration!

# Set up CalInvite configuration for tests
CalInvite.configure do |config|
  config.cache_store = :memory_store
  config.cache_expires_in = 3600 # 1 hour in seconds
  config.timezone = 'UTC'
end

class Minitest::Test
  def setup
    super
    # Clear cache before each test if it exists
    CalInvite.configuration.cache_store&.clear
  end
end
