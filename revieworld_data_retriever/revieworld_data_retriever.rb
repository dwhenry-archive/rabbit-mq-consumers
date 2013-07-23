require 'amqp'
require 'json'
require 'tire'
require 'torque'

class RevieworldDataRetriever
  TOPIC_NAME  = 'revieworld.data-request'
  QUEUE_NAME  = 'revieworld.data-request'
  ROUTING_KEY = 'revieworld.data-request.*'

  def process(url_specification)
    while true do
      response = Net::HTTP.get_response(url_for(url_specification))
      return response.body if response.code =~ /2\d\d/
      sleep(@timeout)
    end
  end

  def url_for(options)
    # TODO: this should be implemented at some stage
    uri = "http://revieworld.live/data_request/#{options['class']}/#{options['conditions']['id']}.#{options['format']}"
    # puts "processing: #{uri}"
    URI.parse(uri)
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

  def initialize(channel, options={})
    @channel = channel
    @timeout = options[:timeout] || 30
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
