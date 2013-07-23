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
      url = url_for(url_specification)
      log(:info, "request data from: #{url}")
      response = Net::HTTP.get_response(url)
      log(:info, response.inspect)
      return response.body if response.code =~ /2\d\d/
      sleep(@timeout)
    end
  end

  def url_for(options)
    # TODO: this should be implemented at some stage
    uri = "#{@host}/data_request/#{options['class']}/#{options['conditions']['id']}.#{options['format']}"
    # puts "processing: #{uri}"
    URI.parse(uri)
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
    @timeout = options[:timeout] || 30
    @host    = options[:host] || 'http://localhost:80'
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
      queue.bind(exchange, routing_key: ROUTING_KEY).subscribe(:ack => true) do |metadata, review_identifier|
        log(:info, "receive message from: #{metadata.reply_to}")
        begin
          @channel.default_exchange.publish(
            process(review_identifier),
            :routing_key    => metadata.reply_to,
            :correlation_id => metadata.message_id,
            :mandatory      => true
          )

          metadata.ack

        rescue => e
          log(:error, "it went wrong: #{e.message}")
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
