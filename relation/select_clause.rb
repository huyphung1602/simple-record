class SelectClause

  def initialize(table_name, col_definitions)
    @table_name = table_name
    @column_names = []
    @value = ''
  end

  def build
    columns_string = is_select_all ? '*' : @column_names.map(&:to_s).join(', ')
    @value = "SELECT #{columns_string} FROM #{@table_name}"

    self
  end

  def update(column_names)
    @column_names = column_names
    self.build
  end

  def value
    @value
  end

  private

  def is_select_all
    @column_names == []
  end
end