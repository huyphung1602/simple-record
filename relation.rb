require './relation/limit_clause.rb'
require './relation/select_clause.rb'
require './relation/where_clause.rb'

class Relation
  def initialize(table_name, col_definitions, primary_key)
    @sql = ''
    @table_name = table_name
    @col_definitions = col_definitions
    @primary_key = primary_key
    @sub_clause = nil
    @association_cache = {}
    @select_clause = nil
    @where_clause = nil
    @limit_clause = nil
  end

  def build(columns, limit: limit)
    @select_clause = ::SelectClause.new(@table_name, @col_definitions).build(column_names)
    @where_clause = ::WhereClause.new(@table_name, @col_definitions, @primary_key).build(columns)
    @limit_clause = ::LimitClause.new(limit)

    self
  end

  def build_chain(columns)
    @where_clause.build_chain(columns)

    self
  end

  def to_sql
    sql = <<~SQL
      #{@select_clause.value}
      #{@where_clause.value}
      #{@limit_clause.value}
    SQL
  end

  private

  def column_names
    @col_definitions.keys
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