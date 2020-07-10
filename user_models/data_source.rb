require './simple_record.rb'

class DataSource < SimpleRecord
  has_many :data_source_tables
end
