class Consumer
  class ReviewElasticSearchWriter < Consumer
    def handle_message(payload)
      log(:info, "Received Message: #{payload.inspect}")
      revieworld_data(class: :reviews, conditions: payload, format: :torque) do |torque_data|
        Torque.to(@options.fetch(:bucket_name), torque_data)
        log(:info, "Torque message written: #{torque_data.inspect}")
      end
    end

    def revieworld_data(query, &block)
      Producer::DirectRevieworld.ask(query, log_level: @log_level, &block)
    end
  end
end
