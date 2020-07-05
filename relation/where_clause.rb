require './connection_adapter/column.rb'

class WhereClause
  def self.build(table_name, columns)
    table_columns = SimpleCache.fetch "#{table_name}_columns"
    final_where_clause = ''

    columns.each_with_index do |(k, v), index|
      method = "build_#{Column.get_column_type(table_columns[k][:format_type])}"
      where_or_and = index == 0 ? 'WHERE' : 'AND'
      where_clause = "#{where_or_and} #{self.send(method, k, v)}"
      final_where_clause += where_clause
    end

    final_where_clause
  end

  def self.build_string(key, value)
    "#{key} = '#{value}'"
  end

  def self.build_datetime(key, value)
    "#{key} = '#{value}'"
  end

  def self.build_integer(key, value)
    "#{key} = #{value}"
  end

  def self.build_boolean(key, value)
    "#{key} = #{value}"
  end
end