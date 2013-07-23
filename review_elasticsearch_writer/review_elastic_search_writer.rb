require 'amqp'
require 'json'
require 'tire'
require 'torque'

require 'pry'
require 'pry-nav'

class ReviewElasticSearchWriter
  TOPIC_NAME  = 'reviews'
  QUEUE_NAME  = 'elasticsearch.review.writer'
  ROUTING_KEY = 'review.*'

  DATA_REQUEST_TOPIC_NAME = 'revieworld.data-request'

  def process(review_identifier)
    message = revieworld_data(class: :reviews, conditions: review_identifier, format: :torque) do |torque_data|
      log(:info, "Torque message started: #{review_identifier.inspect}")
      Torque.to('test-reviews', torque_data)
      log(:info, "Torque message written: #{review_identifier.inspect}")
    end
  end

  def exchange
    @exchange ||= channel.topic(TOPIC_NAME)
  end

# extract..

  attr_reader :channel

  def self.run!
    AMQP.start do
      channel = AMQP::Channel.new
      new(channel).run!
    end
  end

  def initialize(channel, options={})
    @channel = channel
    @log_level = options[:log_level] || :error
  end

  LOG_LEVELS = {
    info: 0,
    warn: 1,
    error: 2
  }

  def log(level, message)
    if LOG_LEVELS[level] >= LOG_LEVELS[@log_level]
      puts message
    end
  end

  def run!
    channel.queue(QUEUE_NAME) do |queue|
      queue.bind(exchange, routing_key: ROUTING_KEY).subscribe do |review_identifier|
        log(:info, "Review update: #{review_identifier.inspect}")
        process JSON.parse(review_identifier )
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
        log(:info, "Review Data received: #{replies_queue.name}")
        yield(JSON.parse(payload, symbolize_names: true))
      end

      log(:info, "Review Data requested: #{replies_queue.name}")
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
