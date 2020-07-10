class Main
  DIRECTORY_PATHS = [
    './connection_adapter/*.rb',
    './database_congfig/*.rb',
    './relation/*.rb',
  ]

  FILE_PATHS = [
    './simple_cache.rb',
    './simple_record.rb',
  ]

  USER_DEFINE_PATH = './user_models/*.rb'

  def self.load_all
    load_sr
    load_ud
  end

  # Load lib files
  def self.load_sr
    load_dir
    load_file
  end

  def self.load_ud
    Dir[USER_DEFINE_PATH].each { |file| load file }
  end

  def self.load_dir
    DIRECTORY_PATHS.each do |dir|
      Dir[dir].each { |file| require file }
    end
  end

  def self.load_file
    FILE_PATHS.each { |file| require file }
  end
end
