require 'active_support/inflector'
require './database_config/database_config.rb'
require './connection_adapter/postgres_adapter.rb'
require './connection_adapter/postgres_connection.rb'

class SimpleRecord
  def self.find key
    sql = <<~SQL
      SELECT #{column_names.join(', ')}
      FROM #{table_name}
      WHERE #{primary_key} = #{key}
      LIMIT 1
    SQL

    pretty_log(sql)

    SimpleCache.fetch "#{table_name}_records" do
      row = conn.exec(sql).values.first
      hash = {}
      column_names.each_with_index do |col_name, index|
        hash[col_name.to_sym] = row[index]
      end
      {
        "#{table_name}_#{key}": hash
      }
    end
    self.new(key, table_name)
  end

  def self.where(hash)
    final_where_clause = ''
    hash.each_with_index do |(k, v), index|
      where_clause = index == 0 ? "WHERE #{k} = #{v}" : " AND #{k} = #{v}"
      final_where_clause += where_clause
    end

    select_clause = "
      SELECT #{column_names.join(', ')}
      FROM #{table_name}
    "

    sql = <<~SQL
      #{select_clause}
      #{final_where_clause}
    SQL

    sql
  end

  private

  def initialize(pk_key, table_name)
    p pk_key
    p table_name
    @pk_key = pk_key
    @table_name = table_name
  end

  def method_missing(method, *args, &block)
    if self.class.column_names.include?(method.to_s)
      SimpleCache.fetch("#{@table_name}_records")["#{@table_name}_#{@pk_key}".to_sym][method.to_sym]
    else
      super
    end
  end

  def self.parse_row(row_array)
    row_array.each do |col|
      column_names
    end
  end

  def self.table_name
    self.name.tableize
  end

  def self.dbname
    ::DatabaseConfig.new('development').dbname
  end

  def self.conn
    SimpleCache.fetch 'conn' do
      ::PostgresConnection.new(dbname).connection
    end
  end

  def self.adapter
    SimpleCache.fetch 'adapter' do
      ::PostgresAdapter.new(conn)
    end
  end

  def self.table_definitions
    adapter.table_definitions
  end

  def self.columns
    adapter.column_definitions(table_name)
  end

  def self.primary_key
    table_definitions[table_name][:key_column]
  end

  def self.column_names
    columns.keys
  end

  def self.pretty_log(input_str)
    input_str.inspect.split('\n').each do |line|
      p line
    end
  end
end
