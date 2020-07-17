class LimitClause
  def initialize
    @value = ''
  end

  def value
    @value
  end

  def build(limit)
    @value = limit.nil? ? '' : "LIMIT #{limit}" 
  end
end
