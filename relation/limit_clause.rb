class LimitClause
  def self.build(limit = -1)
    limit > -1 ? "LIMIT #{limit}" : ''
  end
end