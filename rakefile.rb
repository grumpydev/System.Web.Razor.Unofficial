require './git'
require './executor'
require 'rubygems'
require 'albacore'
require 'FileUtils'

task :default do
  puts "Unoffical Razor nuget builder script"
end

namespace :razor do
  ASPNET_GIT_PATH = 'https://git01.codeplex.com/aspnetwebstack.git'
  WORKING_PATH = 'Working'
  NEW_SOURCE_PATH = 'src'
  RAZOR_DIR = 'System.Web.Razor'
  SOURCE_RAZOR_DIRECTORY = "#{WORKING_PATH}/aspnetwebstack/src/#{RAZOR_DIR}"
  DEST_RAZOR_DIRECTORY = "#{NEW_SOURCE_PATH}/#{RAZOR_DIR}"
  
  Dir.class_eval do
    def self.logged_chdir(dir, &block)
      puts "Entering #{dir}"
      self.chdir(dir, &block)
      puts "Leaving #{dir} (Now: #{Dir.pwd})"
    end
  end
  
  task :clean_working do
    puts "Deleting working folder" if File.exists? WORKING_PATH
    
    FileUtils.rm_rf(WORKING_PATH) if File.exists? WORKING_PATH
  end
  
  task :create_working => :clean_working do
    puts "Creating working folder"

    Dir.mkdir(WORKING_PATH)
  end
  
  task :grab_code => :create_working do
    Dir.logged_chdir WORKING_PATH do
      puts 'Grabbing latest code'
      
      Git.clone ASPNET_GIT_PATH
    end
  end
  
  task :update_source => :grab_code do
    puts "Moving code from #{SOURCE_RAZOR_DIRECTORY} to #{DEST_RAZOR_DIRECTORY}"
    FileUtils.rm_rf(DEST_RAZOR_DIRECTORY) if File.exists? DEST_RAZOR_DIRECTORY
    
    FileUtils.mv(SOURCE_RAZOR_DIRECTORY, DEST_RAZOR_DIRECTORY)
  end
end