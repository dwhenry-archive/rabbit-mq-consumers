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
    @exchange = @channel.topic(ReviewElasticSearchWriter::TOPIC_NAME)
  end

  it 'will add record to elasticsearch' do
    Net::HTTP.stub(:get => message.to_json)

    ReviewElasticSearchWriter.new(@channel).run!
    # Torque.should_receive(:to).with('reviews', message)

    # @exchange.publish({id: 14}.to_json, :key => 'revieworld.data-request.create')
    subsitute_revieworld_data({class: :reviews, format: :torque, conditions: {id: 120}})

    done(0.2) {
      # After #done is invoked, it launches an optional callback
      @channel.queue(ReviewElasticSearchWriter::QUEUE_NAME).delete
      # Here goes the main check
      @data.should == message
    }
  end

  def subsitute_revieworld_data(query)
    @channel.queue("", :exclusive => true, :auto_delete => true) do |replies_queue|
      replies_queue.subscribe do |metadata, payload|
        @data = JSON.parse payload
      end

      reply_exchange.publish(
        query,
        :routing_key => "revieworld.data-request.#{query[:class]}",
        :message_id  => Kernel.rand(10101010).to_s,
        :reply_to    => replies_queue.name
      )
    end
  end

  def reply_exchange
    @channel.topic(ReviewElasticSearchWriter::DATA_REQUEST_TOPIC_NAME)
  end
end