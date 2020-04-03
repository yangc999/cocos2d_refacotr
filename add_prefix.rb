
require 'xcodeproj'
require 'stringio'
require 'pry'
require 'yaml'

$proj = nil
$proj_path = '/home/yangc/testconfuse/com.test.confuse/frameworks/runtime-src/proj.ios_mac/com.test.confuse.xcodeproj'
$prefix = 'XB'
$todo = Array.new
$swap = Hash.new
$header = Array.new
$class = Hash.new
$lua = Array.new

def replace_classname(file)
    path = file.real_path.to_s
    buffer = StringIO.new
    line_count = 0
    File.open(path, 'r').each_line do |line|
        line_count += 1
        li = line.chomp
        if !li.include?('#include') and !li.include?('#import')
            $class.each_key do |c|
                if li.include?(c)
                    nc = '%s%s' % [$prefix, c]
                    puts 'replace %s classname in line %d >>> %s -> %s' % [file.display_name, line_count, c, nc]
                    li = li.gsub(c, nc)
                end
            end
        end
        buffer.puts li
    end
    File.open(path, 'w') do |f|
        f.puts buffer.string 
    end
end

def replace_file(file)
    path = file.real_path.to_s
    dir = File.dirname(path)
    base = File.basename(path)
    new_name = '%s/%s%s' % [dir, $prefix, base]
    puts 'rename >>> %s -> %s' % [path, new_name]
    File.rename(path, new_name)
    new_ref = file.parent.new_reference(new_name)
    $swap[file] = new_ref
end

def replace_head(file)
    path = file.real_path.to_s
    buffer = StringIO.new
    line_count = 0
    File.open(path, 'r').each_line do |line|
        line_count += 1
        li = line.chomp
        if li.include?('#include') or li.include?('#import')
            $header.each do |f|
                if li.include?(f.display_name)
                    nh = '%s%s' % [$prefix, f.display_name]
                    puts 'replace %s header in line %d >>> %s -> %s' % [file.display_name, line_count, f.display_name, nh]
                    li = li.gsub(f.display_name, nh)
                end
            end
        end
        buffer.puts li
    end
    File.open(path, 'w') do |f|
        f.puts buffer.string
    end
end

def replace_target(old_file, new_file)
    $proj.targets.each do |target|
        if target.source_build_phase.include?(old_file)
            puts 'replace target %s >>> %s -> %s' % [target.display_name, old_file.display_name, new_file.display_name]
            target.source_build_phase.add_file_reference(new_file, true)
        end
    end
    old_file.build_files.each { |file| file.remove_from_project }
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
    $swap.each_value do |file|
        replace_head(file)
    end
    $swap.each_value do |file|
        replace_classname(file)
    end
    $todo.each do |file|
        clean_file(file)
    end
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
                $header << child
                path = child.real_path
                File.open(path, 'r').each_line do |line|
                    li = line.chomp
                    if li[0, 5] == 'class'
                        stop = li.length
                        if li.index(':')
                            stop = li.index(':')
                        elsif li.index('{')
                            stop = li.index('{')
                        end
                        cl = li[5..stop-1].strip()
                        $class[cl] = true
                        puts 'find cpp class declare %s' % cl
                    elsif li [0, 10] == '@interface'
                        stop = li.length
                        if li.index(':')
                            stop = li.index(':')
                        elsif li.index('{')
                            stop = li.index('{')
                        end
                        cl = li[10..stop-1].strip()
                        $class[cl] = true
                        puts 'find oc class declare %s' % cl
                    end
                end
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
    $proj.save()
end