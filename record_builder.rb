module RecordBuilder
  def self.included(base)
    base.extend ClassMethods
  end

  def values_after_cast
    attributes = self.instance_variable_get('@attributes')
    attributes[:values_after_cast]
  end

  module ClassMethods
    def build_record_object(array)
      attributes = {}
      values_after_cast = column_names.each_with_object({}).with_index do |(col_name, values_after_cast), index|
        values_after_cast[col_name.to_sym] = array[index]
      end

      attributes[:values_after_cast] = values_after_cast

      self.new.tap do |record|
        record.instance_variable_set('@attributes', attributes)
        record.instance_variable_set('@association_cache', {})
      end
    end
  end
end
