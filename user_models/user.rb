require './simple_record.rb'

class User < SimpleRecord
  has_many :reports, foreign_key: :owner_id, class_name: QueryReport
end
