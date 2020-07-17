class LimitClause
  def initialize(limit)
    @value = limit.nil? ? '' : "LIMIT #{limit}" 
  end

  def value
    @value
  end
end