require 'active_support/inflector'
require './database_config/database_config.rb'
require './connection_adapter/postgres_adapter.rb'
require './connection_adapter/postgres_connection.rb'
require './relation/select_clause.rb'
require './relation/where_clause.rb'
require './relation/limit_clause.rb'

class SimpleRecord
  @reflections = {}

  def self.find(value)
    select_clause = ::SelectClause.build(table_name)
    where_clause = ::WhereClause.new(table_name, get_col_definitions, primary_key)
      .build({primary_key.to_sym => value}).where_clause

    limit_clause = ::LimitClause.build(1)
    sql = build_sql(select_clause, where_clause, limit_clause)

    cache_record = self.get_cache_record(sql)
    self.build_record_object(cache_record.first)
  end

  def self.where(hash)
    ::WhereClause.new(table_name, get_col_definitions, primary_key).build(hash)
  end

  def self.get_final_sql(where_clause, select_column_names = nil)
    select_clause = ::SelectClause.build(table_name, select_column_names)
    sql = build_sql(select_clause, where_clause)
  end

  def self.evaluate_where(where_clause, select_column_names = nil)
    select_clause = ::SelectClause.build(table_name, select_column_names)
    sql = build_sql(select_clause, where_clause)

    cache_record = self.get_cache_record(sql)
    return cache_record if cache_record.first.is_a?(self)

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

      ro.instance_variable_set('@association_cache', {})
    end
  end

  def self.get_cache_record(sql)
    QueryCache.fetch "#{sql}" do
      pretty_log(sql)
      conn.exec(sql).values
    end
  end

  def self.has_many(association_table_name, foreign_key: foreign_key, class_name: class_name)
    association_class_name = class_name.nil? ? association_table_name.to_s.classify : class_name.to_s
    foreign_key = foreign_key.nil? ? self.name.foreign_key : foreign_key.to_s

    # New or fetch table reflection instance
    reflection = SchemaCache.fetch "#{table_name}_reflections" do
      Reflection.new(table_name)
    end

    reflection_hash = {
      association_class_name: association_class_name,
      foreign_key: foreign_key,
      association_type: :has_many,
    }

    reflection.add_reflection(association_table_name, reflection_hash)

    define_method(association_table_name) do
      association_class_name.constantize.where("#{foreign_key}": self.id).tap do |where_clause|
        association_sql = association_class_name.constantize.get_final_sql(where_clause.where_clause)

        association_query_cache = QueryCache.fetch "#{association_sql}"

        association_cache = self.instance_variable_get('@association_cache')

        # Store @association_query_cache
        if association_query_cache
          association_cache["#{association_table_name}".to_sym] = association_query_cache
          self.instance_variable_set('@association_cache', association_cache)
        end

        # Set @association_cache
        where_clause.set_association_cache(association_cache)
      end
    end
  end
end
