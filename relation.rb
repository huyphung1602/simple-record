require './relation/limit_clause.rb'
require './relation/select_clause.rb'
require './relation/where_clause.rb'

class Relation
  def initialize
    @main_sql = ''
    @sub_sql = ''
    @association_cache = {}
    @select_clause = nil
    @where_clause = nil
  end

  def build(table_name)
    @select_clause = ::SelectClause.new(table_name)
    @where_clause = ::WhereClause.new(table_name, col_definitions, primary_key)
  end

  def build_sql(select_clause, where_clause, limit_clause = '')
    sql = <<~SQL
      #{select_clause}
      #{where_clause}
      #{limit_clause}
    SQL
  end
end