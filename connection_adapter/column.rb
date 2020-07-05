class Column
  TYPES_MAP = {
    'integer'=> 'integer',
    'boolean'=> 'boolean',
    'character varying(255)'=> 'string',
    'character varying'=> 'string',
    'timestamp without time zone'=> 'datetime',
    'jsonb'=> 'jsonb',
  }

  def self.get_column_type(type)
    TYPES_MAP[type]
  end
end
