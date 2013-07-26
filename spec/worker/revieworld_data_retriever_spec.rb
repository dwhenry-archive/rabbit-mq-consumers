require 'spec_helper'

module Helpers
  def send_message_and_store_response(query)
    Producer::Direct.new(@exchange, 'revieworld.data-request').ask(query) do |response|
      @result_data = response
    end
  end
end

describe Worker::RevieworldDataRetriever do
  include EventedSpec::AMQPSpec
  include Helpers

  let(:message) { {message: 'hash'} }
  let(:missing_response) { double(:missing_response, code: '404', body: '<<error>>') }
  let(:response) { double(:response, code: '202', body: message.to_json) }

  amqp_before do
    # initializing amqp channel
    @channel   = RabbitMqConsumers.channel
    # using default amqp exchange
    @exchange = Exchanges.revieworld_data_request
  end

  it 'will return data' do
    Net::HTTP.stub(get_response: response)

    Worker::RevieworldDataRetriever.new(log_level: RSpec::LOG_LEVEL, host: 'http://localhost:80')

    send_message_and_store_response({class: :reviews, format: :torque, conditions: {id: 120}})

    done(0.2) {
      # After #done is invoked, it launches an optional callback
      # Here goes the main check
      @result_data.should == message
    }
    RabbitMqConsumers.reset
  end

  it 'will wait for data to appear' do
    Net::HTTP.stub(:get_response).and_return(missing_response, response)

    Worker::RevieworldDataRetriever.new(log_level: RSpec::LOG_LEVEL, timeout: 0.1, host: 'http://localhost:80')

    send_message_and_store_response({class: :reviews, format: :torque, conditions: {id: 120}})

    done(0.2) {
      # After #done is invoked, it launches an optional callback
      # Here goes the main check
      @result_data.should == message
    }

  end
end
