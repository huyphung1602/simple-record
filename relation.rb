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

  def build(columns = {})
    @select_clause = ::SelectClause.new(@table_name, @col_definitions).build
    @where_clause = ::WhereClause.new(@table_name, @col_definitions, @primary_key).build(columns)
    @limit_clause = ::LimitClause.new

    self
  end

  def build_chain(columns = {})
    @where_clause.build_chain(columns)

    self
  end

  def limit(limit_value)
    @limit_clause.build(limit_value)

    self
  end

  def to_sql
    sql = <<~SQL
      #{@select_clause.value}
      #{@where_clause.value}
      #{@limit_clause.value}
    SQL
  end

  def evaluate(*args)
    column_names = args.map(&:to_s)
    @select_clause.update(column_names)

    if @association_cache[@table_name.to_sym]
      @association_cache[@table_name.to_sym]
    else
      @table_name.classify.constantize.evaluate_relation(self.to_sql, column_names)
    end
  end

  def set_association_cache(association_cache)
    @association_cache = association_cache
  end

  private

  def column_names
    @col_definitions.keys
  end

  def method_missing(method, *args, &block)
    case method
    when :where
      self.build_chain(*args)
    when :pluck
      self.evaluate(*args)
    when :first, :last
      self.evaluate.send(method)
    else
      super
    end
  end
end