class Consumer
  def initialize(options={})
    @log_level  = options.delete(:log_level) || :error
    @options    = options
  end

  def log(level, message)
    if LOG_LEVELS[level] >= LOG_LEVELS[@log_level]
      puts "[#{level}] #{message}"
    end
  end
end
