class Worker
  attr_accessor :queue_options

  def initialize(queue_name = AMQ::Protocol::EMPTY_STRING, consumer=nil, &block)
    @queue_name = queue_name

    channel.on_error(&method(:handle_channel_exception))

    @consumer   = consumer
    yield self if block_given?
  end

  def start(options={}, &block)
    bg = block_given?
    channel.queue(@queue_name) do |queue|
      new_queue = bg ? block.call(queue) : queue
      new_queue.subscribe(options, &@consumer.method(:handle_message))
    end
  end

  def handle_channel_exception(channel, channel_close)
    puts "Oops... a channel-level exception: code = #{channel_close.reply_code}, message = #{channel_close.reply_text}"
  end

  def channel
    RabbitMqConsumers.channel
  end
end