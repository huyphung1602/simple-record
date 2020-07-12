class Main
  DIRECTORY_PATHS = [
    './connection_adapter/*.rb',
    './database_congfig/*.rb',
    './relation/*.rb',
    './*.rb'
  ]

  USER_DEFINE_PATH = './user_models/*.rb'

  def self.load_all
    load_dir
    load_ud
  end

  def self.load_ud
    Dir[USER_DEFINE_PATH].each { |file| load file }
  end

  def self.load_dir
    DIRECTORY_PATHS.each do |dir|
      Dir[dir].each { |file| require file }
    end
  end
end
