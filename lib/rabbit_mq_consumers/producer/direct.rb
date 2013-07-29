module RabbitMqConsumers
  class Producer
    class Direct < Producer

      def initialize(exchange, routing_key, options={})
        super(exchange, options)
        @routing_key = routing_key
      end

      def ask(query, &block)
        # TODO: consider if we can declutter this method to allow for simpler subclassing and overridding.
        RabbitMqConsumers.channel.queue("", exclusive: true, auto_delete: true) do |replies_queue|
          replies_queue.subscribe do |_, payload|
            log_response(replies_queue.name)
            json = JSON.parse(payload, symbolize_names: true)
            block.call(json)
          end

          log_sending(replies_queue.name)

          publish(replies_queue, query)
        end
      end

      def publish(replies_queue, query)
        super(
          query,
          routing_key: "#{@routing_key}.#{query[:class]}",
          message_id: Kernel.rand(10101010).to_s,
          reply_to: replies_queue.name
        )
      end

      private

      def log_response(replies_queue_name)
        log(:info, "Direct Query Response for: #{replies_queue_name}")
      end

      def log_sending(replies_queue_name)
        log(:info, "Direct Query Sent for: #{replies_queue_name}")
      end
    end
  end
end
