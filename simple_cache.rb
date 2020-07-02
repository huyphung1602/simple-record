class SimpleCache
  @redis = {}

  def self.fetch key, &block
    if @redis.key?(key)
      # fetch and return result
      puts "fetch from cache"
      @redis[key]
    else
      if block_given?
        # make the DB query and create a new entry for the request result
        puts "did not find key in cache, executing block ..."
        @redis[key] = yield(block)
      end
    end
  end
end
