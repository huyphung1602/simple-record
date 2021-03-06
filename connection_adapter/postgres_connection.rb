require "pg"

class PostgresConnection
  def initialize(dbname)
    @dbname = dbname
  end

  def connect
    PG.connect( dbname: @dbname )
  end
end