module Association
  def self.included(base)
    base.extend ClassMethods
  end

  module ClassMethods
    def has_many(association_table_name, foreign_key: foreign_key, class_name: class_name)
      association_class_name = class_name.nil? ? association_table_name.to_s.classify : class_name.to_s
      foreign_key = foreign_key.nil? ? self.name.foreign_key : foreign_key.to_s
  
      # New or fetch table reflection instance
      reflection = SchemaCache.fetch "#{table_name}_reflections" do
        Reflection.new(table_name)
      end
  
      reflection_hash = {
        association_class_name: association_class_name,
        foreign_key: foreign_key,
        association_type: :has_many,
      }
  
      reflection.add_reflection(association_table_name, reflection_hash)
  
      define_method(association_table_name) do
        association_class_name.constantize.where("#{foreign_key}": self.id)
        # association_class_name.constantize.where("#{foreign_key}": self.id).tap do |where_clause|
        #   association_sql = association_class_name.constantize.get_final_sql(where_clause.where_clause)
  
        #   association_query_cache = QueryCache.fetch "#{association_sql}"
  
        #   association_cache = self.instance_variable_get('@association_cache')
  
        #   # Store @association_query_cache
        #   if association_query_cache
        #     association_cache["#{association_table_name}".to_sym] = association_query_cache
        #     self.instance_variable_set('@association_cache', association_cache)
        #   end
  
        #   # Set @association_cache
        #   where_clause.set_association_cache(association_cache)
        # end
      end
    end    
  end
end