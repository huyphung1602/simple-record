class Column
  def self.column_manipulator(col_definition)
    dbtype =  SchemaCache.fetch('adapter').dbtype
    case dbtype
    when 'postgresql'
      PostgresManipulator.new(col_definition)
    else
      PostgresManipulator.new(col_definition)
    end
  end
end

class PostgresManipulator
  # SQL type -> Ruby type
  SQL_TYPES = {
    'integer'=> 'integer',
    'boolean'=> 'boolean',
    'character varying(255)'=> 'string',
    'character varying'=> 'string',
    'timestamp without time zone'=> 'datetime',
    'jsonb'=> 'jsonb',
  }
  TRUE_VALUES = [
    't',
    'true',
    'y',
    'yes',
    'on',
    '1',
  ]

  def initialize(col_definition)
    @col_definition = col_definition
  end

  def get_column_type(type)
    SQL_TYPES[type]
  end

  def column_name_type
    @col_definition.each_with_object({}) do |(k, v), hash|
      hash[k] = SQL_TYPES[v[:format_type]]
    end
  end

  def ruby_type_converter(value, column_name)
    type = column_name_type[column_name]
    return value if value.nil?

    case type
    when 'integer'
      value.to_i
    when 'boolean'
      TRUE_VALUES.include?(value.downcase)
    when 'string'
      value
    when 'datetime'
      DateTime.parse(value).to_time
    when 'jsonb'
      JSON.parse(value)
    else
      value
    end
  end
end