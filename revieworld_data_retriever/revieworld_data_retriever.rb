require 'amqp'
require 'json'
require 'net/http'


class RevieworldDataRetriever
  QUEUE_NAME  = "revieworld.data-requester"
  ROUTING_KEY = 'revieworld.data-request.*'

  DATA_REQUEST_TOPIC_NAME = 'revieworld.data-request'

  def process(url_specification)
    url = url_for(
      controller: url_specification['class'],
      id: url_specification[:conditions][:id],
      format: url_specification[:format]
    )
    Net::HTTP.get(URI.parse(url))
  end

  def exchange
    @exchange = channel.topic(DATA_REQUEST_TOPIC_NAME, auto_delete: false)
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
    channel.queue(QUEUE_NAME).delete
    channel.queue(QUEUE_NAME) do |queue|
      puts 'www'
      queue.bind(exchange, routing_key: ROUTING_KEY).subscribe do |payload|
        puts 'www2'
        process JSON.parse(payload)
      end
    end

    # channel.queue(QUEUE_NAME) do |queue|
    #   puts 'www'
    #   requests_queue.bind(reply_exchange, routing_key: ROUTING_KEY).subscribe do |payload|
    #     puts 'aaa'
    #     process JSON.parse(payload)

    #     # metadata.ack
    #   end
    # end
    # channel.queue(QUEUE_NAME) do |queue|
    #   queue.bind(exchange, routing_key: ROUTING_KEY).subscribe do |review_identifier|
    #     puts 'aaa'
    #     binding.pry
    #     process JSON.parse(review_identifier)
    #   end
    # end
  rescue Interrupt => e
    puts 'Bye bye!'
    EM.next_tick { AMQP.exit }
    exit(0)
  end


  def reply_exchange
    channel.topic(DATA_REQUEST_TOPIC_NAME)
  end
end
