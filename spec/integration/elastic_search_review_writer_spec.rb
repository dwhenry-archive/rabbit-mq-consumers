require 'spec_helper'

describe 'I can write a review to torque' do
  include EventedSpec::AMQPSpec

  amqp_before do
    @channel   = RabbitMqConsumers
  end

  let(:searchable) { { id: 14, type: 'String', value: 'Some string data' } }
  let(:filterable) { { key: 'product_group_id', value: 120 } }
  let(:response) { {id: 14, locale: 'en-GB', searchable: [searchable], filterable: [filterable]}.to_json }



  before do
    Tire.index('torque-test-reviews').delete
  end

  it 'does stuff' do
    start_workers

    write_review_create_entry_to_rabbit_mq

    check_torque_for_entry
  end



  def start_workers
    Worker::ReviewElasticSearchWriter.new(log_level: RSpec::LOG_LEVEL, bucket_name: 'reviews-test')
    Worker::RevieworldDataRetriever.new(log_level: RSpec::LOG_LEVEL, timeout: 0.1, host: 'http://localhost:8080')

    HttpServer.start(response)
  end

  def write_review_create_entry_to_rabbit_mq
    Producer.new(Exchanges.reviews).publish({id: 14}, :key => 'review.create', ack: true)
  end

  def check_torque_for_entry
    done(2) {
      HttpServer.stop

      Tire.index('torque-test-reviews').refresh
      Torque.query('reviews-test', '*').should == [{:id => 14}]
    }
  end
end
