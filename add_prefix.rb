
require 'xcodeproj'
require 'pry'

puts 'input xcodeproj file path:'
proj_path = gets.chomp
#proj_path = '/home/yangc/testconfuse/com.test.confuse/frameworks/runtime-src/proj.ios_mac/com.test.confuse.xcodeproj'
if File.exists?(proj_path) and File.directory?(proj_path)
    proj_dir = File.dirname(proj_path)
    proj = Xcodeproj::Project.open(proj_path)
    puts proj_dir
    proj.files.each do |file|
        ext = File.extname(file.path)
        if ext == '.h' or ext == '.hpp'
            puts 'name:' + file.display_name
            puts 'path:' + file.path
            puts 'parent:' + file.parent.display_name
        end
        if ext == '.m' or ext == '.mm'
            puts 'name:' + file.display_name
            puts 'path:' + file.path
            puts 'parent:' + file.parent.display_name
        end
        if ext == '.c' or ext == '.cpp'
            puts 'name:' + file.display_name
            puts 'path:' + file.path
            puts 'parent:' + file.parent.display_name
        end
    end
end