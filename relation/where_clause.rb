require 'active_support/inflector'
require './connection_adapter/column.rb'
require './simple_record.rb'

class WhereClause
  def initialize(table_name)
    @table_name = table_name
    @where_clause = ''
  end

  def build(columns)
    columns.each_with_index do |(k, v), index|
      method = "build_#{Column.get_column_type(table_columns[k][:format_type])}"
      where_or_and = index == 0 ? 'WHERE' : 'AND'
      this_clause = "#{where_or_and} #{self.send(method, k, v)}"
      @where_clause += this_clause
    end

    self
  end

  def build_chain(columns)
    columns.each_with_index do |(k, v), index|
      method = "build_#{Column.get_column_type(table_columns[k][:format_type])}"
      this_clause = " AND #{self.send(method, k, v)}"
      @where_clause += this_clause
    end

    self
  end

  def evaluate
    @table_name.classify.constantize.evaluate_where(@where_clause)
  end

  def value
    @where_clause
  end

  private

  def table_columns
    SimpleCache.fetch "#{@table_name}_columns"
  end

  def build_string(key, value)
    if value.is_a? Array
      return '1=0' if value.empty?
      value = value.map do |v|
        v.is_a?(String) ? "'#{v}'" : nil
      end.compact

      "#{key} in (#{value.join(', ')})"
    else
      "#{key} = '#{value}'"
    end
  end

  def build_datetime(key, value)
    if value.is_a? Array
      return '1=0' if value.empty?
      value = value.map do |v|
        v.is_a?(String) ? "'#{v}'" : nil
      end.compact

      "#{key} in (#{value.join(', ')})"
    else
      "#{key} = '#{value}'"
    end
  end

  def build_integer(key, value)
    if value.is_a? Array
      return '1=0' if value.empty?
      value = value.map do |v|
        v.is_a?(Integer) ? v : nil
      end.compact

      "#{key} in (#{value.join(', ')})"
    else
      "#{key} = '#{value}'"
    end
  end

  def build_boolean(key, value)
    if value.is_a? Array
      return '1=0' if value.empty?
      value = value.map do |v|
        v.is_a?(Boolean) ? v : nil
      end.compact

      "#{key} in (#{value.join(', ')})"
    else
      "#{key} = '#{value}'"
    end
  end

  def method_missing(method, *args, &block)
    if method == :where
      self.build_chain(*args)
    elsif [:first, :last].include?(method)
      self.evaluate.send(method)
    else
      super
    end
  end
end