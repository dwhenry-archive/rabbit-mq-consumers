require 'spec_helper'

describe 'It writes data to torque' do
  include EventedSpec::AMQPSpec
  let(:message) { {message: 'hash'} }

   amqp_before do
     # initializing amqp channel
     @channel   = RabbitMqConsumers.channel
     # using default amqp exchange
     @exchange = Exchanges.reviews
   end

  it 'will add record to elasticsearch' do
    #@channel.queue(Worker::ReviewElasticSearchWriter::QUEUE_NAME).delete

    subsitute_revieworld_data({class: :reviews, format: :torque}, message)

    Worker::ReviewElasticSearchWriter.new(log_level: :info, bucket_name: 'reviews-test')
    Torque.should_receive(:to).with('reviews-test', message)

    @exchange.publish({id: 14}.to_json, :key => 'review.create')

    done(2) {
       # After #done is invoked, it launches an optional callback
       # @channel.queue(ReviewElasticSearchWriter::QUEUE_NAME).delete
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
    Exchanges.revieworld_data_request
  end
end