require "pg"

class PostgresConnection
  def initialize(dbname)
    @dbname = dbname
  end

  def connection
    @connection ||= PG.connect( dbname: @dbname )
  end
end