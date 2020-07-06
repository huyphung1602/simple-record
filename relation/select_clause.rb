class SelectClause
  def self.build(table_name, column_names)
    "SELECT #{column_names.join(', ')} FROM #{table_name}"
  end
end