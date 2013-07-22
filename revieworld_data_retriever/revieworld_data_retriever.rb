require 'amqp'
require 'json'
require 'tire'
require 'torque'

class ReviewElasticSearchWriter
  TOPIC_NAME  = 'revieworld.data-request'
  QUEUE_NAME  = 'revieworld.data-request'
  ROUTING_KEY = 'revieworld.data-request.*'

  DATA_REQUEST_TOPIC_NAME = 'revieworld.data-request'

  def process(url_specification)
    url = url_for(
      controller: url_specification['class'],
      id: url_specification['conditions']['id'],
      format: url_specification['format']
    )
    Net::HTTP.get(URI.parse(url))
  end

  def url_for(options)
    ''
  end

  def exchange
    @exchange ||= channel.topic(TOPIC_NAME, auto_delete: true)
  end

# extract..

  attr_reader :channel

  def self.run!
    AMQP.start do
      channel = AMQP::Channel.new
      new(channel).run!
    end
  end

  def initialize(channel)
    @channel = channel
  end

  def run!
    channel.queue(QUEUE_NAME) do |queue|
      queue.bind(exchange, routing_key: ROUTING_KEY).subscribe(:ack => true) do |metadata, review_identifier|
        begin
          @channel.default_exchange.publish(
            process(review_identifier),
            :routing_key    => metadata.reply_to,
            :correlation_id => metadata.message_id,
            :mandatory      => true
          )

          metadata.ack

        rescue => e
          binding.pry
          raise
        end
      end
    end
  rescue Interrupt => e
    puts 'Bye bye!'
    EM.next_tick { AMQP.exit }
    exit(0)
  end


end
