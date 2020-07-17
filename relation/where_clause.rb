require 'active_support/inflector'
require './connection_adapter/column.rb'
require './simple_record.rb'

class WhereClause
  def initialize(table_name, col_definitions, primary_key)
    @col_definitions = col_definitions
    @table_name = table_name
    @primary_key = primary_key
    @value = ''
  end

  def build(columns)
    columns.each_with_index do |(k, v), index|
      method = "build_#{Column.get_column_type(@col_definitions[k][:format_type])}"
      where_or_and = index == 0 ? 'WHERE' : 'AND'
      @value += "#{where_or_and} #{self.send(method, k, v)}"
    end

    self
  end

  def build_chain(columns)
    @association_cache = {}

    columns.each_with_index do |(k, v), index|
      method = "build_#{Column.get_column_type(@col_definitions[k][:format_type])}"
      @value += " AND #{self.send(method, k, v)}"
    end

    self
  end

  def value
    @value
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
        v = v.to_i if v.respond_to?('to_i')
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

  def column_exist?(col_name)
    !!@col_definitions[col_name]
  end
end
