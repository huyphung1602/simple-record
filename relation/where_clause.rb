require 'active_support/inflector'
require './connection_adapter/column.rb'
require './simple_record.rb'

class WhereClause
  def initialize(table_name, col_definitions, primary_key)
    @col_definitions = col_definitions
    @table_name = table_name
    @primary_key = primary_key
    @where_clause = ''
  end

  def build(columns)
    columns.each_with_index do |(k, v), index|
      method = "build_#{Column.get_column_type(@col_definitions[k][:format_type])}"
      where_or_and = index == 0 ? 'WHERE' : 'AND'
      this_clause = "#{where_or_and} #{self.send(method, k, v)}"
      @where_clause += this_clause
    end

    self
  end

  def build_chain(columns)
    columns.each_with_index do |(k, v), index|
      method = "build_#{Column.get_column_type(@col_definitions[k][:format_type])}"
      this_clause = " AND #{self.send(method, k, v)}"
      @where_clause += this_clause
    end

    self
  end

  def evaluate(*args)
    column_names = args.map(&:to_s) if args.any?
    @table_name.classify.constantize.evaluate_where(@where_clause, column_names)
  end

  def where_clause
    @where_clause
  end

  def includes(association_name)
    association_class = association_name.to_s.classify.constantize
    main_query_result = self.evaluate
    primary_keys = main_query_result.map { |r| r.send(@primary_key) }

    reflection = SchemaCache.fetch "#{@table_name}_reflections"
    foreign_key = reflection.reflections[association_name][:foreign_key]
    includes_query_result = association_class.where("#{foreign_key}": primary_keys).evaluate
    includes_result_distribution(includes_query_result, association_class, foreign_key)
    main_query_result
  end

  def order_by(*args)
    args.each do |col_name|
      raise "Column #{col_name.to_s} does not exist" unless column_exist?(col_name.to_sym)
    end
    @where_clause += " ORDER BY #{args.map(&:to_s).join(', ')}"

    self
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

  def column_exist?(col_name)
    !!@col_definitions[col_name]
  end

  def includes_result_distribution(includes_query_result, association_class, foreign_key)
    hash = {}
    includes_query_result.each do |r|
      where_clause = association_class.where("#{foreign_key}": r.send(foreign_key)).where_clause
      cache_key = association_class.get_final_sql(where_clause)

      if hash[cache_key].nil?
        hash[cache_key] = []
      else
        hash[cache_key] << r
      end
    end

    hash.each do |k, v|
      QueryCache.fetch k do
        v
      end
    end
  end
end
