class Worker
  class RevieworldDataRetriever < Worker
    # valid options
    # :log_level (optional)
    # :timeout (optional)
    # :host

    QUEUE_NAME  = 'revieworld.data-request'
    ROUTING_KEY = 'revieworld.data-request.*'

    def initialize(options={})
      options[:timeout] ||= 30
      super(QUEUE_NAME, Consumer::RevieworldDataRetriever.new(options))
      start(
          queue: {:auto_delete => true},
          subscribe: {ack: true}
      ) { |queue| queue.bind(Exchanges.revieworld_data_request, routing_key: ROUTING_KEY) }
    end
  end
end
