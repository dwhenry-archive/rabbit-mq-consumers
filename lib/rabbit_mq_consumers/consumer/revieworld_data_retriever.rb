class Consumer
  class RevieworldDataRetriever < Consumer
    def handle_message(metadata, review_identifier)
      log(:info, "receive message from: #{metadata.reply_to}")

      Exchanges.default.publish(
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
        begin
          response = Net::HTTP.get_response(url)
        rescue Errno::ECONNREFUSED
          # TODO: this should really send an email if the server is down for toooo long
          #log(:warn, 'Server appears to be down...')
          sleep @options.fetch(:timeout)
          retry
        end
        if response.code =~ /2\d\d/
          log(:info, "received data: #{response.body} from: #{url}")
          return response.body
        end
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
