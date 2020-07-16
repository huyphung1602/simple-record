class SelectClause

  def initialize(table_name)
    @table_name = table_name
    @value = ''
  end

  def self.build(column_names = nil)
    columns_string = column_names.nil? ? '*' : column_names.map(&:to_s).join(', ')
    @value = "SELECT #{columns_string} FROM #{table_name}"
  end
end