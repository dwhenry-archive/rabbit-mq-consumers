module RabbitMqConsumers
  class Producer
    class DirectRevieworld < Direct
      def self.ask(query, options={}, &block)
        new(options).ask(query, &block)
      end

      def initialize(options={})
        super(Exchanges.revieworld_data_request, 'revieworld.data-request', options)
      end

      private

      def log_response(replies_queue_name)
        log(:info, "Revieworld Direct Query Response for: #{replies_queue_name}")
      end

      def log_sending(replies_queue_name)
        log(:info, "Revieworld Direct Query Sent for: #{replies_queue_name}")
      end
    end
  end
end
