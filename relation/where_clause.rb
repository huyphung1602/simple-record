require 'active_support/inflector'
require './connection_adapter/column.rb'
require './simple_record.rb'

class WhereClause
  def initialize(table_name, table_columns)
    @table_columns = table_columns
    @table_name = table_name
    @where_clause = ''
  end

  def build(columns)
    columns.each_with_index do |(k, v), index|
      method = "build_#{Column.get_column_type(@table_columns[k][:format_type])}"
      where_or_and = index == 0 ? 'WHERE' : 'AND'
      this_clause = "#{where_or_and} #{self.send(method, k, v)}"
      @where_clause += this_clause
    end

    self
  end

  def build_chain(columns)
    columns.each_with_index do |(k, v), index|
      method = "build_#{Column.get_column_type(@table_columns[k][:format_type])}"
      this_clause = " AND #{self.send(method, k, v)}"
      @where_clause += this_clause
    end

    self
  end

  def evaluate(*args)
    column_names = args.map(&:to_s) if args.any?
    @table_name.classify.constantize.evaluate_where(@where_clause, column_names)
  end

  def value
    @where_clause
  end

  private

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
    case method
    when :where
      self.build_chain(*args)
    when :all
      self.evaluate
    when :pluck
      self.evaluate(*args)
    when :first, :last
      self.evaluate.send(method)
    else
      super
    end
  end
end