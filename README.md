# GorgService
[![Code Climate](https://codeclimate.com/github/Zooip/gorg_service/badges/gpa.svg)](https://codeclimate.com/github/Zooip/gorg_service) [![Test Coverage](https://codeclimate.com/github/Zooip/gorg_service/badges/coverage.svg)](https://codeclimate.com/github/Zooip/gorg_service/coverage) [![Build Status](https://travis-ci.org/Zooip/gorg_service.svg?branch=master)](https://travis-ci.org/Zooip/gorg_service) [![Gem Version](https://badge.fury.io/rb/gorg_service.svg)](https://badge.fury.io/rb/gorg_service) [![Dependency Status](https://gemnasium.com/badges/github.com/Zooip/gorg_service.svg)](https://gemnasium.com/github.com/Zooip/gorg_service)

Standard RabbitMQ bot used in Gadz.org SOA

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
  
  Before being used, GorgService must be configured. In Rails app, put it in an Initializer.

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
  # time before trying again on softfail in milliseconds (temporary error)
  # c.rabbitmq_deferred_time = 1800000 # 30min
  # 
  # maximum number of try before discard a message
  # c.rabbitmq_max_attempts = 48 # 24h with default deferring delay
  #
  # The routing key used when sending a message to the central log system (Hardfail or Warning)
  # Central logging is disable if nil
  # c.log_routing_key = nil
  #
  # Routing hash
  #  map routing_key of received message with MessageHandler 
  #  exemple:
  # c.message_handler_map={
  #   "some.routing.key" => MyMessageHandler,
  #   "Another.routing.key" => OtherMessageHandler,
  #   "third.routing.key" => MyMessageHandler,
  # }
  c.message_handler_map= {} #TODO : Set my routing hash

 end
```

## Usage

To start the RabbitMQ consummer use :
```ruby
my_service = GorgService.new
my_service.run
```
### Routing and MessageHandler
When running, GorgService act as a consumer on Gadz.org RabbitMQ network.
It bind its queue on the main exchange and subscribes to routing keys defines in `message_handler_map`

Each received message will be routed to the corresponding `MessageHandler`. AMQP wildcards are supported.The first key to match the incomiing routing key will be used.

A `MessageHandler` is a kind of controller. This is where you put the message is processed.
A `MessageHandler` expect a `GorgService::Message` as param of its `initializer`method.

Here is an exemple `MessageHandler` :
```ruby
require 'json'
require 'json-schema' #Checkout https://github.com/ruby-json-schema/json-schema

class ExampleMessageHandler < GorgService::MessageHandler

  EXPECTED_SCHEMA = {
    "type" => "object",
    "required" => ["user_id"],
    "properties" => {
      "user_id" => {"type" => "integer"}
    }
  }
  
  def initialize(msg)
    data=msg.data
    begin
      JSON::Validator.validate!(EXPECTED_SCHEMA, data)
    rescue JSON::Schema::ValidationError => e
      #This message can't be processed, it will be discarded
      raise_hardfail("Invalid message",e)
    end

    begin
      MyAPI.send(msg.data)
    rescue MyAPI::UnavailableConnection => e
      # This message can be processed but external resources
      # are not available at this moment, retry later
      raise_softfail("Can't connect to MyAPI",e)
    end
  end
end
```

As showed in this example,`GorgService::MessageHandler` provides 2 helpers :

 - `raise_hardfail`: This will raise a `HardfailError`exception. The message can't be processed and will never be. It is logged and send back to main exchange for audit purpose.

 - `raise_softfail`: This will raise a `SoftfailError`exception. The message can't be processed at this moment but may be processed in future : connection problems, rate limiting API, etc. It is sent to a deferred queue where it will be delayed for `rabbitmq_deferred_time`millisecconds before being sent back in the main exchange for re-queuing.

Each one of this helpers expect two params :

 - `message` : The information to be displayed in message's error log
 - `exception` (optional) : The runtime exception causing the fail, for debug purpose

### Message structure
`GorgService::Message` is defined [here](https://github.com/Zooip/gorg_service/blob/master/lib/gorg_service/message.rb)

It provides the following attributes :

 - `event` : this is the same as the routing key
 - `id`: message UUID
 - `errors`: `Hash` containing the message error log with previous errors
 - `data`: `Hash` containing the data to be processed
 - `creation_time`: message emission date as `DateTime`
 - `sender` : message producer id

## To Do

 - Internal logs using Logger
 - Class definition of messages error logs instead of Hash
 - Allow disable JSON Schema Validation on incomming messages

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/Zooip/gorg_service.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

