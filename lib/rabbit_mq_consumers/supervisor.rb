LOG_LEVELS = {
    info: 0,
    warn: 1,
    error: 2
}

class Supervisor
  def self.start_from_config(path)
    # TODO: read file.. start server
  end

  def start(options={})
    options.each do |name, settings|
      start_supervising(name, settings)
    end
  end

  def stop
    runner.shutdown
  end

private

  def runner
    @runner ||= Celluloid::SupervisionGroup.run!
  end

  def start_supervising(name, settings)
    runner.pool(
      settings.fetch(:class),
      as: name,
      args: settings[:args] || [],
      size: settings[:size] || 1
    )
  end
end
