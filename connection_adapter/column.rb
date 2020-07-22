class Column
  # SQL type -> Ruby type
  POSTGRESQL_TYPES = {
    'integer'=> 'integer',
    'boolean'=> 'boolean',
    'character varying(255)'=> 'string',
    'character varying'=> 'string',
    'timestamp without time zone'=> 'datetime',
    'jsonb'=> 'jsonb',
  }
  POSTGRESQL_TRUE = [
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
    case @dbtype
    when 'postgresql'
      POSTGRESQL_TYPES[type]
    else
      POSTGRESQL_TYPES[type]
    end
  end

  def column_name_type
    @col_definition.each_with_object({}) do |(k, v), hash|
      hash[k] = POSTGRESQL_TYPES[v[:format_type]]
    end
  end

  def ruby_type_converter(value, column_name)
    type = column_name_type[column_name]
    return value if value.nil?

    case type
    when 'integer'
      value.to_s
    when 'boolean'
      POSTGRESQL_TRUE.include?(value.downcase)
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

  private

  def dbtype
    SchemaCache.fetch('adapter').dbtype
  end
end
