require 'rspec'
require 'evented-spec'
require 'rack'
require_relative '../review_elasticsearch_writer/review_elastic_search_writer'
require_relative '../revieworld_data_retriever/revieworld_data_retriever'



describe 'I can write a review to torque' do
  include EventedSpec::AMQPSpec

  amqp_before do
    # initializing amqp channel
    @channel   = AMQP::Channel.new
    @channel.on_error { |channel, channel_close|
      puts "Oops... a channel-level exception: code = #{channel_close.reply_code}, message = #{channel_close.reply_text}"
    }
    # using default amqp exchange
    @exchange = @channel.topic(ReviewElasticSearchWriter::TOPIC_NAME)
  end

  it 'does stuff' do
    Tire.index('torque-test-reviews').delete
    # @channel.queue(RevieworldDataRetriever::QUEUE_NAME).delete
    # @channel.queue(ReviewElasticSearchWriter::QUEUE_NAME).delete

    start_everything

    # delayed(0.5) {
      write_review_create_entry_to_rabbit_mq
    # }

    # delayed(3) {
      check_torque_for_entry
    # }
  end

  module HttpServer
    def start
      @thread = Thread.start do
        app.start
      end
      sleep 1 # give it a chance to start
    end

    def stop
      # @app && @app.server.stop
    end

    def app
      searchable = { id: 14, type: 'String', value: 'Some string data' }
      filterable = { key: 'product_group_id', value: 120 }
      json = {id: 14, locale: 'en-GB', searchable: [searchable], filterable: [filterable]}.to_json

      @app ||= Rack::Server.new(builder: "run lambda { |env| [200, {'Content-Type' => 'text/plain'}, ['#{json}']] }")
    end

    extend self
  end

  def start_everything
    ReviewElasticSearchWriter.new(@channel, log_level: :info).run!
    RevieworldDataRetriever.new(@channel, host: 'http://localhost:8080', log_level: :info).run!
    HttpServer.start
  end

  def write_review_create_entry_to_rabbit_mq
    @exchange.publish({id: 14}.to_json, :key => 'review.create', ack: true)
  end

  def check_torque_for_entry
    done(0.2) {
      # After #done is invoked, it launches an optional callback
      # @channel.queue(RevieworldDataRetriever::QUEUE_NAME).delete
      # @channel.queue(ReviewElasticSearchWriter::QUEUE_NAME).delete
      HttpServer.stop

      # Here goes the main check
      Tire.index('torque-test-reviews').refresh
      Torque.query('test-reviews', '*').should == [{:id => 14}]
    }
  end
end