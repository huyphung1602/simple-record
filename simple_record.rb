require 'active_support/inflector'
require './database_config/database_config.rb'
require './connection_adapter/postgres_adapter.rb'
require './connection_adapter/postgres_connection.rb'
require './relation/select_clause.rb'
require './relation/where_clause.rb'
require './relation/limit_clause.rb'

class SimpleRecord
  def self.find(value)
    select_clause = ::SelectClause.build(table_name)
    where_clause = ::WhereClause.new(table_name).build({primary_key.to_sym => value}).value
    limit_clause = ::LimitClause.build(1)
    sql = build_sql(select_clause, where_clause, limit_clause)

    pretty_log(sql)

    cache_record = self.get_cache_record(sql, value)
    self.build_record_object(cache_record["#{table_name}_#{value}".to_sym])
  end

  def self.where(hash)
    get_table_columns
    ::WhereClause.new(table_name).build(hash)
  end

  def self.evaluate_where(where_clause)
    select_clause = ::SelectClause.build(table_name, column_names)
    sql = build_sql(select_clause, where_clause)
    conn.exec(sql).values
  end

  private

  def method_missing(method, *args, &block)
    if self.class.column_names.include?(method.to_s)
      self.instance_variable_get("@#{method.to_s}")
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

  def self.get_table_columns
    adapter.column_definitions(table_name)
  end

  def self.primary_key
    table_definitions[table_name][:key_column]
  end

  def self.column_names
    get_table_columns.keys.map(&:to_s)
  end

  def self.pretty_log(input_str)
    input_str.inspect.split('\n').each do |line|
      line = line.gsub(/\"/, '')
      next if line.empty?
      print "#{line} "
    end
    print "\n"
  end

  def self.build_sql(select_clause, where_clause, limit_clause = '')
    sql = <<~SQL
      #{select_clause}
      #{where_clause}
      #{limit_clause}
    SQL
  end

  def self.build_record_object(hash)
    hash.each_with_object(self.new) do |(k, v), record_object|
      record_object.instance_variable_set("@#{k}", v)
      record_object
    end
  end

  def self.get_cache_record(sql, id)
    SimpleCache.fetch "#{table_name}_records" do
      row = conn.exec(sql).values.first
      hash = {}
      column_names.each_with_index do |col_name, index|
        hash[col_name.to_sym] = row[index]
      end

      {
        "#{table_name}_#{id}": hash
      }
    end
  end
end
