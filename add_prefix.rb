#! /usr/bin/ruby

require 'xcodeproj'
require 'stringio'
require 'yaml'

$proj = nil
$proj_path = '/home/yangc/testconfuse/com.test.confuse/frameworks/runtime-src/proj.ios_mac/com.test.confuse.xcodeproj'
$prefix = 'XB'
$todo = Array.new
$xib = Array.new
$swap = Hash.new
$header = Array.new
$class = Hash.new
$lua = Hash.new
$lua['classes'] = Array.new

def replace_classname(file)
    path = file.real_path.to_s
    if File.exists?(path)
        buffer = StringIO.new
        line_count = 0
        File.open(path, 'r').each_line do |line|
            line_count += 1
            li = line.chomp
            if !li.include?('#include') and !li.include?('#import')
                $class.each_key do |c|
                    if li.include?(c) and !li.include?('set%s' % c) and !li.include?('get%s' % c)
                        nc = '%s%s' % [$prefix, c]
                        if li.include?('tolua_usertype')
                            ot = li.scan(/"(.*)"/)[0][0]
                            nt = ot.gsub(c, nc)
                            $lua['classes'] << {'old'=>ot, 'new'=>nt}
                        end
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
end

def replace_file(file)
    path = file.real_path.to_s
    if File.exists?(path)
        dir = File.dirname(path)
        base = File.basename(path)
        new_name = '%s/%s%s' % [dir, $prefix, base]
        puts 'rename >>> %s -> %s' % [path, new_name]
        File.rename(path, new_name)
        new_ref = file.parent.new_reference(new_name)
        $swap[file] = new_ref
    end
end

def replace_head(file)
    path = file.real_path.to_s
    if File.exists?(path)
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

def replace_xib(file)
    path = file.real_path.to_s
    if File.exists?(path)
        buffer = StringIO.new
        line_count = 0
        File.open(path, 'r').each_line do |line|
            line_count += 1
            li = line.chomp
            $class.each_key do |c|
                if li.include?(c)
                    nc = '%s%s' % [$prefix, c]
                    li = li.gsub(c, nc)
                end
            end
            buffer.puts li
        end
        File.open(path, 'w') do |f|
            f.puts buffer.string
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
    $swap.each_value do |file|
        replace_head(file)
    end
    $swap.each_value do |file|
        replace_classname(file)
    end
    $xib.each_value do |file|
        replace_xib(file)
    end
    $todo.each do |file|
        clean_file(file)
    end
    lua_path = '%s/lua.yaml' % $proj.main_group.real_path.to_s
    if File.exists?(lua_path)
        File.delete(lua_path)
    end
    File.open(lua_path, 'a+') do |f|
        f.puts $lua.to_yaml
    end
end

def visit()
    $proj.files.each do |file|
        ext = File.extname(file.path)
        if ext == '.xib'
            $xib << file
        elsif ext == '.m' or ext == '.mm'
            $todo << file
        elsif ext == '.c' or ext == '.cpp'
            $todo << file
        elsif ext == '.h' or ext == '.hpp'
            if file.path.include?('Bridging-Header')
                next
            end
            $todo << file
            $header << file
            path = file.real_path
            if File.exists?(path)
                File.open(path, 'r').each_line do |line|
                    li = line.chomp
                    if li.strip()[0, 5] == 'class'
                        stop = li.length
                        if li.index(':')
                            stop = li.index(':')
                        elsif li.index('{')
                            stop = li.index('{')
                        elsif li.index(';')
                            stop = li.index(';')
                        end
                        cl = li[5..stop-1].strip().gsub(/[A-Z]+_DLL/, '').strip()
                        $class[cl] = true
                        puts 'find cpp class declare %s' % cl
                    elsif li[0, 10] == '@interface'
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

if ARGV[0] != nil
    $prefix = ARGV[0]
else   
    puts 'input prefix to add:'
    head = gets.chomp
    $prefix = head.length > 0 ? head : $prefix
end

if ARGV[1] != nil
    $proj_path = ARGV[1]
else
    puts 'input xcodeproj file path:'
    path = gets.chomp
    $proj_path = path.length > 0 ? path : $proj_path    
end

if File.exists?($proj_path) and File.directory?($proj_path)
    $proj = Xcodeproj::Project.open($proj_path)
    visit()
    refact()
    $proj.save()
end