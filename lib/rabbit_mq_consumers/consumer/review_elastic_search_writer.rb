class Consumer
  class ReviewElasticSearchWriter < Consumers
    def handle_message(payload)
      revieworld_data(class: :reviews, conditions: payload, format: :torque) do |torque_data|
        Torque.to(@options.fetch(:bucket_name), torque_data)
        log(:info, "Torque message written: #{payload.inspect}")
      end
    end

    def revieworld_data(query)
      # Publisher::Direct(queue_name, queue_options, &callback)
      RabbitMqConsumers.channel.queue("", :exclusive => true, :auto_delete => true) do |replies_queue|
        replies_queue.subscribe do |metadata, payload|
          log(:info, "Review Data received: #{replies_queue.name}")
          yield(JSON.parse(payload, symbolize_names: true))
        end

        log(:info, "Review Data requested: #{replies_queue.name}")
        Exchanges.revieworld_data_request.publish(
          query.to_json,
          :routing_key => "revieworld.data-request.#{query[:class]}",
          :message_id  => Kernel.rand(10101010).to_s,
          :reply_to    => replies_queue.name
        )
      end
    end
  end
end