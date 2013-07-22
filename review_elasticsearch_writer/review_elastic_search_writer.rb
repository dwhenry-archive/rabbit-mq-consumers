require 'amqp'
require 'json'
require 'tire'
require 'torque'

class ReviewElasticSearchWriter
  TOPIC_NAME  = 'reviews'
  QUEUE_NAME  = 'elasticsearch.review.writer'
  ROUTING_KEY = 'review.*'

  DATA_REQUEST_TOPIC_NAME = 'revieworld.data-request'

  def process(review_identifier)
    message = revieworld_data(class: :reviews, conditions: review_identifier, format: :torque) do |torque_data|
      Torque.to('reviews', torque_data)
    end
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
      queue.bind(exchange, routing_key: ROUTING_KEY).subscribe do |review_identifier|
        process JSON.parse(review_identifier)
      end
    end
  rescue Interrupt => e
    puts 'Bye bye!'
    EM.next_tick { AMQP.exit }
    exit(0)
  end

  def revieworld_data(query)
    channel.queue("", :exclusive => true, :auto_delete => true) do |replies_queue|
      replies_queue.subscribe do |metadata, payload|
        yield(JSON.parse(payload))
      end

      reply_exchange.publish(
        query.to_json,
        :routing_key => "revieworld.data-request.#{query[:class]}",
        :message_id  => Kernel.rand(10101010).to_s,
        :reply_to    => replies_queue.name
      )
    end
  end

  def reply_exchange
    channel.topic(DATA_REQUEST_TOPIC_NAME)
  end
end
