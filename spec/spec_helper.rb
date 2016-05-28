require "codeclimate-test-reporter"
require 'bogus/rspec'
CodeClimate::TestReporter.start

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'gorg_service'
