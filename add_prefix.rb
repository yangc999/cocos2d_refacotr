
require 'xcodeproj'
require 'pry'

$proj = nil
$proj_path = '/home/yangc/testconfuse/com.test.confuse/frameworks/runtime-src/proj.ios_mac/com.test.confuse.xcodeproj'
$prefix = 'pre'
$todo = Array.new
$swap = Hash.new

def replace_file(file)
    path = file.real_path.to_s
    dir = File.dirname(path)
    base = File.basename(path)
    new_name = '%s/%s_%s' % [dir, $prefix, base]
    puts "%s -> %s" % [path, new_name]
    File.rename(path, new_name)
    new_ref = file.parent.new_reference(new_name)
    $swap[file] = new_ref
end

def replace_head(file)

end

def replace_target(old_file, new_file)
    $proj.targets.each do |target|
        if target.source_build_phase.include?(old_file)
            target.source_build_phase.remove_file_reference(old_file)
            target.source_build_phase.add_file_reference(new_file, true)
        end
    end
end

def clean_file(file)
    file.remove_from_project()
end

def refact()
    $todo.each do |file|
        replace_file(file)
    end
    $swap.each do |old_file, new_file|
        replace_target(old_file, new_file)
    end
    $todo.each do |file|
        clean_file(file)
    end
    $proj.save()
end

def visit(children)
    children.each do |child|
        if child.class == Xcodeproj::Project::Object::PBXGroup
            visit(child.children)
        elsif child.class == Xcodeproj::Project::Object::PBXFileReference
            ext = File.extname(child.path)
            if ext == '.m' or ext == '.mm'
                $todo << child
            elsif ext == '.c' or ext == '.cpp'
                $todo << child          
            elsif ext == '.h' or ext == '.hpp'
                $todo << child
            end
        end
    end
end

puts 'input prefix to add:'
head = gets.chomp
$prefix = head.length > 0 ? head : $prefix

puts 'input xcodeproj file path:'
path = gets.chomp
$proj_path = path.length > 0 ? path : $proj_path
if File.exists?($proj_path) and File.directory?($proj_path)
    $proj = Xcodeproj::Project.open($proj_path)
    visit($proj.main_group.children)
    refact()
end