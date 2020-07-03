class PostgresAdapter
  def initialize(connection)
    @conn = connection
  end

  def column_definitions(table_name)
    sql = <<~SQL
      SELECT a.attname, format_type(a.atttypid, a.atttypmod),
              pg_get_expr(d.adbin, d.adrelid), a.attnotnull, a.atttypid, a.atttypmod,
              c.collname, col_description(a.attrelid, a.attnum) AS comment
        FROM pg_attribute a
        LEFT JOIN pg_attrdef d ON a.attrelid = d.adrelid AND a.attnum = d.adnum
        LEFT JOIN pg_type t ON a.atttypid = t.oid
        LEFT JOIN pg_collation c ON a.attcollation = c.oid AND a.attcollation <> t.typcollation
        WHERE a.attrelid = '#{table_name}'::regclass
          AND a.attnum > 0 AND NOT a.attisdropped
        ORDER BY a.attnum
    SQL

    SimpleCache.fetch "#{table_name}_columns" do
      column_name, format_type, pg_get_expr, attnotnull, atttypid, atttypmod, collname, comment = @conn.exec(sql).values
      @conn.exec(sql).values.inject({}) do |cols, col_values|
        column_name, format_type, pg_get_expr, attnotnull, atttypid, atttypmod, collname, comment = col_values
        cols[column_name] = {
          format_type: format_type,
          pg_get_expr: pg_get_expr,
          attnotnull: attnotnull,
          atttypid: atttypid,
          atttypmod: atttypmod,
          collname: collname,
          comment: comment,
        }
        cols
      end
    end
  end

  def table_definitions
    sql = <<~SQL
      select
        kcu.table_schema,
        kcu.table_name,
        tco.constraint_name,
        kcu.ordinal_position as position,
        kcu.column_name as key_column
      from
        information_schema.table_constraints tco
        join information_schema.key_column_usage kcu on kcu.constraint_name = tco.constraint_name
        and kcu.constraint_schema = tco.constraint_schema
        and kcu.constraint_name = tco.constraint_name
      where
        tco.constraint_type = 'PRIMARY KEY'
      order by
        kcu.table_schema,
        kcu.table_name,
        position;
    SQL

    SimpleCache.fetch "table_definitions" do
      @conn.exec(sql).values.inject({}) do |tables, table_values|
        table_schema, table_name, constraint_name, position, key_column = table_values
        tables[table_name] = {
          table_schema: table_schema,
          table_name: table_name,
          constraint_name: constraint_name,
          position: position,
          key_column: key_column,
        }
        tables
      end
    end
  end
end