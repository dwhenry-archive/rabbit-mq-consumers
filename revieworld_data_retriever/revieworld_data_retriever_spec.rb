require 'rspec'
require 'evented-spec'
require 'pry'
require 'pry-nav'
require_relative 'revieworld_data_retriever'

describe 'It writes data to torque' do
  include EventedSpec::AMQPSpec
  let(:message) { {'message' => 'hash'} }

  amqp_before do
    # initializing amqp channel
    @channel   = AMQP::Channel.new
    # using default amqp exchange
  end

  it 'returns RW data in json format when it exists' do
    # Net::HTTP.stub(:get => message.to_json)

    RevieworldDataRetriever.new(@channel).run!

    # amqp(:spec_timeout => 0.5) do
    @channel.queue("", :exclusive => true, :auto_delete => true) do |replies_queue|
      replies_queue.subscribe do |metadata, payload|
        puts 'aaa'
        @message == payload.to_json
      end

      reply_exchange.publish(
        {
          class: :reviews,
          conditions: message,
          format: :torque
        }.to_json,
        :routing_key => "revieworld.data-request.reviews",
        :message_id  => Kernel.rand(10101010).to_s,
        :reply_to    => replies_queue.name
      )
    end

    # @exchange.publish({id: 14}.to_json, :key => 'review.create')
# sleep 10
    done(0.2) {
      # After #done is invoked, it launches an optional callback
      @channel.queue(RevieworldDataRetriever::QUEUE_NAME).delete

      # Here goes the main check
    }
    @message.should == message
  end

  def reply_exchange
    # @reply_exchange
    @channel.topic(RevieworldDataRetriever::DATA_REQUEST_TOPIC_NAME)
  end
end