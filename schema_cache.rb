class SchemaCache
  @redis = {}

  def self.fetch key, &block
    if @redis.key?(key)
      # fetch and return result
      # p "fetch from cache"
      @redis[key]
    else
      if block_given?
        # make the DB query and create a new entry for the request result
        # p "did not find key in cache, executing block ..."
        @redis[key] = yield(block)
      end
    end
  end

  def self.clear(key = nil)
    if key
      @redis.delete(key)
    else
      @redis = {}
    end
  end
end
