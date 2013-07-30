=Rabbit MQ Consumers

==Supervisor

Is a Celluloid supervisor whose responsibilities including the starting and running of worker processes.

TODO: Explain how you can configure which workers and numbers of each worker you wish the supervisor to manage

==Worker

A worker's behaviour is to subscribe a consumer to a RabbitMQ queue, applying relevant settings.

All workers must be a subclass of ```RabbitMqConsumers::Worker``` and should follow the example given below

```ruby
 def initialize(options={})
   super('sample.queue.name', Consumer::SampleConsumer.new(options))
   start
 end
```

Additional parameters can be passed to the start method to customize queue and subscription configuration.

```ruby
start(
  queue:     { auto_delete: true },
  subscribe: { ack: true }
)
```

You may also define a callback on the queue, this must return a AMQP queue object.

```ruby
start { |queue| queue.bind(Exchanges.default, routing_key: 'routing.keys') }
```

==Consumer

A consumer is responsible for handling messages passed to it.

All consumers must be a subclass of ```RabbitMqConsumers::Consumer``` and must implement the method ```handle_message```.

The two forms of ```handle_message``` depend on whether or not the queue subscription has asked for acknowledgement.

With:

```ruby
def handle_message(metadata, payload)
  log(:info, "Received Message: #{payload.inspect}")
end
```

Without:

```ruby
def handle_message(payload)
  log(:info, "Received Message: #{payload.inspect}")
end
```

==Producer

Wraps RabbitMQ exchange publish method into a class. This can be included in consumers who wish to publish
onto additional exchanges.

You may subclass ```RabbitMqConsumers::Producer``` and implement your own custom publisher.

==Exchange

This gives a global end-point for accessing named exchanges, avoiding the passing of named exchanges or strings.

```ruby
class MyExchanges < RabbitMqConsumers::Exchanges

  def self.my_exchange
    instance.my_exchange
  end

  def my_exchange
    @my_exchange ||= channel.topic('my_exchange')
  end
end
```

==Logger

TODO: Implement

=Consumer Examples

TODO: How to write a good consumer class
TODO: How to write a consumer that can publish

=Testing

TODO: Provide example about how to implement your own tests for a worker, consumer and publisher.

=running the test using nailgun

Start a nailgun server in the background:

    jruby --ng-server &

then you can run a single test using:

    jruby --ng -S rspec /path/to/spec

alternatively add the file:

    jspec

to your path and run:

    jspec /path/to/spec
