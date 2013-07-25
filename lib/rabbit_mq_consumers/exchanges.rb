class Exchanges
  class << self
    delegate :revieworld_data_request, :reviews,
      to: :instance

    def instance
      @exchanges = new
    end

    def reset
      @exchanges = nil
    end
  end

  def default
    @default ||= ''
  end

  def reviews
    @reviews ||= channel.topic('reviews')
  end

  def revieworld_data_request
    @revieworld_data_request ||= channel.topic('revieworld.data-request')
  end

  private

  def channel
    RabbitMqConsumers.channel
  end
end