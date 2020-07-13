require './database_config/database_config.rb'
require './connection_adapter/postgres_adapter.rb'
require './connection_adapter/postgres_connection.rb'

class DatabaseInitiator
  DB_MAPPER = {
    'postgresql' => { connection_class: ::PostgresConnection, adapter_class: ::PostgresAdapter }
  }

  def initialize(env_name, path: './config/database.yml')
    @env_name = env_name
    @path = path
  end

  def execute
    dbconfig = ::DatabaseConfig.new(@env_name, path: @path)
    dbname = dbconfig.dbname
    dbtype = dbconfig.dbtype

    # Create connection
    conn = SchemaCache.fetch 'conn' do
      DB_MAPPER[dbtype][:connection_class].new(dbname).connect
    end

    # Create adapter
    adapter = SchemaCache.fetch 'adapter' do
      DB_MAPPER[dbtype][:adapter_class].new(conn)
    end

    adapter.table_definitions
  end
end
