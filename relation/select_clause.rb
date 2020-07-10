class SelectClause
  def self.build(table_name, column_names = nil)
    columns_string = column_names.nil? ? '*' : column_names.join(', ')
    "SELECT #{columns_string} FROM #{table_name}"
  end
end