class LimitClause
  def initialize(limit = -1)
    @value = limit > -1 ? "LIMIT #{limit}" : ''
  end
end