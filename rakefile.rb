require './git'
require './executor'
require 'rubygems'
require 'albacore'
require 'FileUtils'

task :default do
  puts "Unoffical Razor nuget builder script"
end

namespace :razor do
  ## Can't grab this from the assembly info because it uses ifdefs'
  VERSION = "2.0"

  ASPNET_GIT_PATH = 'https://git01.codeplex.com/aspnetwebstack.git'
  WORKING_PATH = 'Working'
  RAZOR_DIR = 'System.Web.Razor'
  SOURCE_PATH = 'aspnetwebstack/src'
  RAZOR_PROJECT = "#{WORKING_PATH}/#{SOURCE_PATH}/#{RAZOR_DIR}/System.Web.Razor.csproj"
  BIN_LOCATION = "#{WORKING_PATH}/#{SOURCE_PATH}/bin/Release"
  SHARED_ASSEMBLY_INFO = "#{WORKING_PATH}/#{SOURCE_PATH}/CommonAssemblyInfo.cs"
  CONFIGURATION = 'Release'
  NUGET_EXE = 'tools/nuget.exe'
  NUSPEC = 'System.Web.Razor.Unofficial.nuspec'
  NUGET_OUTPUT_DIR = 'output'

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
  task :build_nuget => :build do
    puts "Version #{VERSION}"

    update_xml NUSPEC do |xml|
      xml.root.elements["metadata/version"].text = VERSION
    end

    FileUtils.rm_rf(NUGET_OUTPUT_DIR) if File.exists? NUGET_OUTPUT_DIR
    Dir.mkdir(NUGET_OUTPUT_DIR)

    nuget = NuGetPack.new
    nuget.command = NUGET_EXE
    nuget.nuspec = NUSPEC
    nuget.output = NUGET_OUTPUT_DIR
    nuget.execute
  end

  desc "Pushes the nuget packages in the nuget folder up to the nuget gallary and symbolsource.org. Also publishes the packages into the feeds."
  task :nuget_publish, :api_key do |task, args|
    nupkgs = FileList["#{NUGET_OUTPUT_DIR}/*.nupkg"]

    nupkgs.each do |nupkg|
        puts "Pushing #{nupkg}"
        nuget_push = NuGetPush.new
	      nuget_push.apikey = args.api_key if !args.empty?
        nuget_push.command = NUGET_EXE
        nuget_push.package = "\"" + nupkg + "\""
        nuget_push.create_only = false
        nuget_push.execute
    end
  end

  def update_xml(xml_path)
    #Open up the xml file
    xml_file = File.new(xml_path)
    xml = REXML::Document.new xml_file

    #Allow caller to make the changes
    yield xml

    xml_file.close

    #Save the changes
    xml_file = File.open(xml_path, "w")
    formatter = REXML::Formatters::Default.new(5)
    formatter.write(xml, xml_file)
    xml_file.close
  end
end