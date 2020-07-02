class Main
  DIRECTORY_PATHS = [
    './connection_adapter/*.rb',
    './database_congfig/*.rb',
  ]

  FILE_PATHS = [
    './simple_cache.rb'
  ]

  def self.load_all
    load_dir
    load_file
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
