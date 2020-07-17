module RecordBuilder
  def self.included(base)
    base.extend ClassMethods
  end

  module ClassMethods
    def build_record_object(array)
      record_object = self.new
      record_object.tap do |ro|
        column_names.each_with_index do |col_name, index|
          ro.instance_variable_set("@#{col_name}", array[index])
        end

        ro.instance_variable_set('@association_cache', {})
      end
    end
  end
end
