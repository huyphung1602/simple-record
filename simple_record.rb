require 'active_support/inflector'
require './database_config/database_config.rb'
require './connection_adapter/postgres_adapter.rb'
require './connection_adapter/postgres_connection.rb'
require './record_builder.rb'
require './association.rb'
require './connection_adapter/column.rb'

class SimpleRecord
  include RecordBuilder
  include Association

  @reflections = {}

  def self.find(value)
    relation = Relation.new(table_name, get_col_definitions, primary_key)
    relation.build({primary_key.to_sym => value}).limit(1)
    sql = relation.to_sql

    cache_record = self.get_cache_record(sql)
    self.build_record_object(cache_record.first)
  end

  def self.where(hash)
    relation = Relation.new(table_name, get_col_definitions, primary_key)
    relation.build(hash)
  end

  def self.all
    relation = Relation.new(table_name, get_col_definitions, primary_key)
    relation.build
  end

  def self.evaluate_relation(sql, select_column_names)
    cache_record = self.get_cache_record(sql, select_column_names)
    return cache_record if cache_record.first.is_a?(self)

    if select_column_names.size == 0
      cache_record.map { |r| self.build_record_object(r) }
    else
      select_column_names.size == 1 ? cache_record.flatten : cache_record
    end
  end

  private

  def method_missing(method, *args, &block)
    if self.class.column_names.include?(method.to_s)
      p self
      self.values_before_cast[method]
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

  def self.conn
    SchemaCache.fetch 'conn'
  end

  def self.adapter
    SchemaCache.fetch 'adapter'
  end

  def self.get_table_definitions
    adapter.table_definitions
  end

  def self.get_col_definitions
    adapter.column_definitions(table_name)
  end

  def self.primary_key
    get_table_definitions[table_name][:key_column]
  end

  def self.column_names
    get_col_definitions.keys.map(&:to_s)
  end

  def self.pretty_log(input_str)
    input_str.inspect.split('\n').each do |line|
      line = line.gsub(/\"/, '')
      next if line.empty?
      print "#{line} "
    end
    print "\n"
  end

  def self.get_cache_record(sql, select_column_names = [])
    QueryCache.fetch "#{sql}" do
      pretty_log(sql)
      values = conn.exec(sql).values
      values = ruby_type_convert(values, select_column_names)
    end
  end

  def self.columns_manipulator
    Column.new(get_col_definitions)
  end

  def self.ruby_type_convert(result, column_names)
    column_names = column_names.any? ? column_names : get_col_definitions.keys

    [].tap do |values|
      result.each do |row|
        value = []
        column_names.each_with_index do |column_name, index|
          value << columns_manipulator.ruby_type_converter(row[index], column_name.to_sym)
        end
        values << value
      end
    end
  end
end
