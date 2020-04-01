
require 'xcodeproj'

proj = nil
puts 'input xcodeproj file path:'
proj_path = gets.chomp
if File.exists?(proj_path) and File.directory?(proj_path)
    proj = Xcodeproj::Project.open(proj_path)
end