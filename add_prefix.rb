
require 'xcodeproj'
require 'pry'

$prefix = 'pre'

def rename(path)
    dir = File.dirname(path)
    base = File.basename(path)
    new_name = '%s/%s_%s' % [dir, $prefix, base] 
    puts "%s -> %s" % [path, new_name]
end

def visit(children)
    children.each do |child|
        if child.class == Xcodeproj::Project::Object::PBXGroup
            visit(child.children)
        elsif child.class == Xcodeproj::Project::Object::PBXFileReference
            ext = File.extname(child.path)
            if ext == '.m' or ext == '.mm'
                puts child.display_name
                rename(child.real_path.to_s)
            elsif ext == '.c' or ext == '.cpp'
                puts child.display_name
                rename(child.real_path.to_s)          
            elsif ext == '.h' or ext == '.hpp'
                puts child.display_name
                rename(child.real_path.to_s)
            end
        end
    end
end

puts 'input prefix to add:'
head = gets.chomp
$prefix = head.length > 0 ? head : $prefix

puts 'input xcodeproj file path:'
proj_path = gets.chomp
#proj_path = '/home/yangc/testconfuse/com.test.confuse/frameworks/runtime-src/proj.ios_mac/com.test.confuse.xcodeproj'
if File.exists?(proj_path) and File.directory?(proj_path)
    proj = Xcodeproj::Project.open(proj_path)
    puts proj.main_group.path
    visit(proj.main_group.children)
    proj.files.each do |file|
        ext = File.extname(file.path)
    end
end