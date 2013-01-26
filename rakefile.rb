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
  RAZOR_DIR = 'System.Web.Razor'
  SOURCE_PATH = 'aspnetwebstack/src'
  RAZOR_PROJECT = "#{WORKING_PATH}/#{SOURCE_PATH}/#{RAZOR_DIR}/System.Web.Razor.csproj"
  BIN_LOCATION = "#{WORKING_PATH}/#{SOURCE_PATH}/bin/Release"
  CONFIGURATION = 'Release'

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

  desc "Builds the project"
  msbuild :build => :grab_code do |msb|
      msb.properties :configuration => CONFIGURATION
      msb.targets :Clean, :Build
      msb.solution = RAZOR_PROJECT
  end

  desc "Builds tne nuget"
  end
end