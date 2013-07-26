class Producer
  def initialize(exchange, options={})
    @exchange = exchange
    @log_level  = options.delete(:log_level) || :error
    @options    = options
  end

  def log(level, message)
    if LOG_LEVELS[level] >= LOG_LEVELS[@log_level]
      puts "[#{level}] #{message}"
    end
  end

  def publish(message, options = {})
    @exchange.publish(message, options)
  end

  def handle_channel_exception(channel, channel_close)
    puts "Oops... a channel-level exception: code = #{channel_close.reply_code}, message = #{channel_close.reply_text}"
  end
end
