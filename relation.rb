require './relation/limit_clause.rb'
require './relation/select_clause.rb'
require './relation/where_clause.rb'

class Relation
  def initialize(table_name, col_definitions, primary_key)
    @sql = ''
    @table_name = table_name
    @col_definitions = col_definitions
    @primary_key = primary_key
    @includes_params = []
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

  def includes(*args)
    args.each do |association_name|
      reflection = SchemaCache.fetch "#{@table_name}_reflections"
      foreign_key = reflection.reflections[association_name][:foreign_key]
      @includes_params << [association_name.to_s.classify.constantize, foreign_key]
    end

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

    result = if @association_cache[@table_name.to_sym]
      @association_cache[@table_name.to_sym]
    else
      @table_name.classify.constantize.evaluate_relation(self.to_sql, column_names)
    end

    if @includes_params.any?
      primary_keys = result.map { |r| r.send(@primary_key) }

      @includes_params.each do |params|
        association_class, foreign_key = params
        includes_query_result = association_class.where("#{foreign_key}": primary_keys).evaluate
        includes_result_distribution(includes_query_result, association_class, foreign_key)
      end
    end

    result
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

  def includes_result_distribution(includes_query_result, association_class, foreign_key)
    hash = {}
    includes_query_result.each do |r|
      sql = association_class.where("#{foreign_key}": r.send(foreign_key)).to_sql

      if hash[sql].nil?
        hash[sql] = []
      else
        hash[sql] << r
      end
    end

    hash.each do |k, v|
      QueryCache.fetch k do
        v
      end
    end
  end
end