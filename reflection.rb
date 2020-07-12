class Reflection
  def initialize(table_name)
    @table_name = table_name
    @reflections = {}
  end

  def add_reflection(key, value)
    @reflections[key] = value
  end

  def get_reflection(key)
    @reflections[key]
  end
end