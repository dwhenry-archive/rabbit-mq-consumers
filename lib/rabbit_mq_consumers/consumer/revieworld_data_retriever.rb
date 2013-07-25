class Consumer
  class RevieworldDataRetriever < Consumers
    def handle_message(metadata, review_identifier)
      log(:info, "receive message from: #{metadata.reply_to}")

      RabbitMqConsumers.channel.default_exchange.publish(
          process(review_identifier),
          :routing_key    => metadata.reply_to,
          :correlation_id => metadata.message_id,
          :mandatory      => true
      )

      metadata.ack
    end

    def process(url_specification)
      while true do
        url = url_for(url_specification)
        log(:info, "request data from: #{url}")
        response = Net::HTTP.get_response(url)
        log(:info, response.inspect)
        log(:info, response.code)
        return response.body if response.code =~ /2\d\d/
        sleep(@options.fetch(:timeout))
      end
    end

    def url_for(options)
      # TODO: this should be implemented at some stage
      uri = "#{@options.fetch(:host)}/data_request/#{options['class']}/#{options['conditions']['id']}.#{options['format']}"
      # puts "processing: #{uri}"
      URI.parse(uri)
    end
  end
end
