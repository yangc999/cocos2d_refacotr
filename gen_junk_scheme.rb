#! /usr/bin/ruby

require 'xcodeproj'
require 'yaml'

$scheme = Hash.new
$groupDict = Array.new
$classDict = Array.new
$methodDict = Array.new
$retDict = ['NSString*', 'void', 'int', 'BOOL']


if ARGV[0] != nil
    $proj_path = ARGV[0]
else
    puts 'input xcodeproj file path:'
    path = gets.chomp
    $proj_path = path.length > 0 ? path : $proj_path    
end

if File.exists?($proj_path) and File.directory?($proj_path)
    $proj = Xcodeproj::Project.open($proj_path)
    yaml_path = '%s/junk.yaml' % $proj.main_group.real_path.to_s
    File.open(yaml_path, 'a+') do |f|
        f.puts $scheme.to_yaml
    end
end
