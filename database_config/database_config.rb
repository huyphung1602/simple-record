require "yaml"

class DatabaseConfig
  def initialize(path: './config/database.yml')
    @path = path
  end

  def get_database(key: 'development')
    database_config_file = YAML.load_file(@path)
    database_config_file[key]
  end
end
