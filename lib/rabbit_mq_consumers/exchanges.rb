module Exchanges
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

  extend self
end