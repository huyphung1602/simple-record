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
    where_clause = ::WhereClause.new(table_name, get_table_columns).build({primary_key.to_sym => value}).value
    limit_clause = ::LimitClause.build(1)
    sql = build_sql(select_clause, where_clause, limit_clause)

    pretty_log(sql)

    cache_record = self.get_cache_record(sql)
    self.build_record_object(cache_record.first)
  end

  def self.where(hash)
    ::WhereClause.new(table_name, get_table_columns).build(hash)
  end

  def self.evaluate_where(select_clause, where_clause, select_column_names = nil)
    sql = build_sql(select_clause, where_clause)

    pretty_log(sql)

    cache_record = self.get_cache_record(sql)
    if select_column_names.nil? 
      cache_record.map { |r| self.build_record_object(r) }
    else
      select_column_names.size > 1 ? cache_record : cache_record.flatten
    end
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

  def self.build_record_object(array)
    record_object = self.new
    record_object.tap do |ro|
      column_names.each_with_index do |col_name, index|
        ro.instance_variable_set("@#{col_name}", array[index])
      end
    end
  end

  def self.get_cache_record(sql)
    SimpleCache.fetch "#{sql}" do
      conn.exec(sql).values
    end
  end

  def self.has_many(association_table_name)
    define_method(association_table_name) do
      ::WhereClause
        .new(association_table_name.to_s, self.class.adapter.column_definitions(association_table_name))
        .build("#{self.class.name.foreign_key}": self.id)
    end
  end
end
