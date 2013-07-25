class Worker
  class ReviewElasticSearchWriter < Worker
    # valid options
    # :bucket_name
    # :log_level (optional)

    QUEUE_NAME  = 'elasticsearch.review.writer'
    ROUTING_KEY = 'review.*'

    def initialize(options={})
      super(QUEUE_NAME, Consumer::ReviewElasticSearchWriter.new(options))
      start { |queue| queue.bind(Exchanges.reviews, routing_key: ROUTING_KEY) }
    end
  end
end