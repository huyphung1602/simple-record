class SelectClause

  def initialize(table_name, col_definitions)
    @table_name = table_name
    @col_definitions = col_definitions
    @value = ''
  end

  def build(column_names)
    columns_string = is_select_all?(column_names) ? '*' : column_names.map(&:to_s).join(', ')
    @value = "SELECT #{columns_string} FROM #{@table_name}"

    self
  end

  def value
    @value
  end

  def all_column_names
    @col_definitions.keys
  end

  def is_select_all?(column_names)
    all_column_names - column_names == []
  end
end