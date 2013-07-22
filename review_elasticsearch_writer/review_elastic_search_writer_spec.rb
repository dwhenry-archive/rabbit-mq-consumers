require 'rspec'
require 'evented-spec'
require 'pry'
require 'pry-nav'
require_relative 'review_elastic_search_writer'

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
    subsitute_revieworld_data({class: :reviews, format: :torque}, message)

    ReviewElasticSearchWriter.new(@channel).run!
    Torque.should_receive(:to).with('reviews', message)

    @exchange.publish({id: 14}.to_json, :key => 'review.create')

    done(0.2) {
      # After #done is invoked, it launches an optional callback

      # Here goes the main check
    }
  end

  def subsitute_revieworld_data(matcher, response)
    requests_queue = @channel.queue("revieworld.data-request", :exclusive => true, :auto_delete => true)

    # requests_queue = @channel.queue("revieworld.data-request", :exclusive => true, :auto_delete => true)
    requests_queue.bind(reply_exchange, routing_key: "revieworld.data-request.*").subscribe(:ack => true) do |metadata, payload|
      @channel.default_exchange.publish(response.to_json,
                                       :routing_key    => metadata.reply_to,
                                       :correlation_id => metadata.message_id,
                                       :mandatory      => true)

      metadata.ack
    end
  end

  def reply_exchange
    @channel.topic(ReviewElasticSearchWriter::DATA_REQUEST_TOPIC_NAME)
  end
end