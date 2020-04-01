
require 'xcodeproj'
require 'pry'

def visit(children)
    children.each do |child|
        if child.class == Xcodeproj::Project::Object::PBXGroup
            puts 'group'
            puts child.display_name
            puts child.path
            visit(child.children)
        elsif child.class == Xcodeproj::Project::Object::PBXFileReference
            puts 'file'
            puts child.display_name
            puts child.path            
        end
    end
end

puts 'input xcodeproj file path:'
proj_path = gets.chomp
#proj_path = '/home/yangc/testconfuse/com.test.confuse/frameworks/runtime-src/proj.ios_mac/com.test.confuse.xcodeproj'
if File.exists?(proj_path) and File.directory?(proj_path)
    proj_dir = File.dirname(proj_path)
    proj = Xcodeproj::Project.open(proj_path)
    puts proj.main_group.path
    visit(proj.main_group.children)
    proj.files.each do |file|
        ext = File.extname(file.path)
    end
end