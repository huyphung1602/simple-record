class Reflection
  attr_reader :reflections

  def initialize(table_name)
    @table_name = table_name
    @reflections = {}
  end

  def add_reflection(key, value)
    @reflections[key] = value
  end
end