module RabbitMqConsumers
  class Consumer
    class ReviewElasticSearchWriter < Consumer
      def handle_message(payload)
        log(:info, "Received Message: #{payload.inspect}")
        revieworld_data(class: :reviews, conditions: payload, format: :torque) do |torque_data|
          Torque.to(@options.fetch(:bucket_name), torque_data)
          log(:info, "Torque message written: #{torque_data.inspect}")
        end
      end
    end
  end
end
