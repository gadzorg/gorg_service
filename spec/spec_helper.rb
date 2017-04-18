require "simplecov"
SimpleCov.start

require 'bogus/rspec'
require 'gorg_service/support/conf/rabbitmq_config.rb'
$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'gorg_service'
