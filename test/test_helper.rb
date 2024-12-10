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
