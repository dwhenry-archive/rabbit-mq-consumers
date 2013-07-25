require 'amqp'
require 'json'
require 'tire'
require 'torque'

Dir[File.join(File.dirname(__FILE__), "rabbit_mq_consumers/**/*.rb")].each {|f| require f}


module RabbitMqConsumers
  def channel
    @channel ||= AMQP::Channel.new
  end

  extend self
end