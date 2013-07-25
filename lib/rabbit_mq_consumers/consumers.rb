class Consumers
  def initialize(options={})
    @log_level  = options.delete(:log_level) || :error
    @options    = options
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
end
