require "codeclimate-test-reporter"
require 'bogus/rspec'
require 'gorg_service/support/conf/rabbitmq_config.rb'

CodeClimate::TestReporter.start

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'gorg_service'
