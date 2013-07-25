require 'rspec'
require 'evented-spec'
require 'pry'
require 'pry-nav'

require 'pry'
require 'pry-nav'
require_relative '../lib/rabbit_mq_consumers'

RSpec.configure do |config|
  config.order = 'random'
  config.before do
    RabbitMqConsumers.reset
  end
end


