# GorgService
[![Code Climate](https://codeclimate.com/github/Zooip/gorg_service/badges/gpa.svg)](https://codeclimate.com/github/Zooip/gorg_service) [![Test Coverage](https://codeclimate.com/github/Zooip/gorg_service/badges/coverage.svg)](https://codeclimate.com/github/Zooip/gorg_service/coverage) [![Build Status](https://travis-ci.org/Zooip/gorg_service.svg?branch=master)](https://travis-ci.org/Zooip/gorg_service)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'gorg_service'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install gorg_service

## Setup
  
  Before being used GramV1Client must be configured. In Rails app, put it in an Initializer.

```ruby
GorgService.configure do |c|
  # application name for display usage
  c.application_name="My Application Name"
  # application id used to find message from this producer
  c.application_id="my_app_id"

  ## RabbitMQ configuration
  # 
  ### Authentification
  # If your RabbitMQ server is password protected put it here
  #
  # c.rabbitmq_user = nil
  # c.rabbitmq_password = nil
  #  
  ### Network configuration :
  #
  # c.rabbitmq_host = "localhost"
  # c.rabbitmq_port = 5672
  #
  #
  # c.rabbitmq_queue_name = c.application_name
  # c.rabbitmq_exchange_name = "exchange"
  #
  # time before trying again on softfail (temporary error)
  # c.rabbitmq_deferred_time = 1800000 # 30min
  # 
  # maximum number of try before discard a message
  # c.rabbitmq_max_attempts = 48 # 24h with default deferring delay

 end
```

## Usage

TODO: Write usage instructions here

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/Zooip/gorg_service.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

