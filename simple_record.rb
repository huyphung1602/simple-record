require 'active_support/inflector'
require './database_config/database_config.rb'
require './connection_adapter/postgres_adapter.rb'
require './connection_adapter/postgres_connection.rb'

class SimpleRecord
  def self.find key
    sql = <<~SQL
      SELECT #{column_names.join(', ')}
      FROM #{table_name}
      WHERE #{primary_key} = #{key}
      LIMIT 1
    SQL

    pretty_log(sql)
    conn.exec(sql).values.first
  end

  private

  def self.table_name
    self.name.tableize
  end

  def self.dbname
    ::DatabaseConfig.new('development').dbname
  end

  def self.conn
    SimpleCache.fetch 'conn' do
      ::PostgresConnection.new(dbname).connection
    end
  end

  def self.adapter
    SimpleCache.fetch 'adapter' do
      ::PostgresAdapter.new(conn)
    end
  end

  def self.table_definitions
    adapter.table_definitions
  end

  def self.columns
    adapter.column_definitions(table_name)
  end

  def self.primary_key
    table_definitions[table_name][:key_column]
  end

  def self.column_names
    columns.keys
  end

  def self.pretty_log(input_str)
    input_str.inspect.split('\n').each do |line|
      p line
    end
  end
end
