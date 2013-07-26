require 'rspec'
require 'evented-spec'
require 'pry'
require 'pry-nav'

require 'pry'
require 'pry-nav'
require_relative '../lib/rabbit_mq_consumers'

Dir[File.join(File.dirname(__FILE__), "support/**/*.rb")].each {|f| require f}

#RSpec::LOG_LEVEL = :info
RSpec::LOG_LEVEL = :error

RSpec.configure do |config|
  config.order = 'random'
  config.before do
    RabbitMqConsumers.reset
  end
end


