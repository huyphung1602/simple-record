require "yaml"

class DatabaseConfig
  def initialize(env_name, path: './config/database.yml')
    @env_name = env_name
    @path = path
  end

  def get_database
    database_config_file = YAML.load_file(@path)
    database_config_file[@env_name]
  end
end
