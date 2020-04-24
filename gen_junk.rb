#! /usr/bin/ruby

require 'xcodeproj'
require 'stringio'
require 'yaml'

$junk = nil
$proj = nil
$proj_path = '/home/yangc/testconfuse/com.test.confuse/frameworks/runtime-src/proj.ios_mac/com.test.confuse.xcodeproj'

def genDir(meta)
    root_path = $proj.main_group.real_path.to_s
    dir_path = '%s/%s' % [root_path, meta.group]
    if File.exists?(dir_path)
        Dir.foreach(dir_path) do |file_path|
            if file_path != '.' and file_path != '..'
                File.delete('%s/%s' % [dir_path, file_path])
            end
        end
        Dir.rmdir(dir_path)
    end    
    Dir.mkdir(dir_path)
    group = $proj.main_group.find_subpath(File.join('AddOns', meta.group), true)
    group.set_source_tree('<absolute>')
    group.set_path(dir_path)
end

def genCode(meta)
    group = $proj.main_group.find_subpath(File.join('AddOns', meta.group), true)
    root_path = $proj.main_group.real_path.to_s
    dir_path = '%s/%s' % [root_path, meta.group]
    meta.classes.each do |cl|
        h_path = '%s/%s.h' % [dir_path, cl.className]
        c_path = '%s/%s.m' % [dir_path, cl.className]
        File.open(h_path) do |file|
            file.puts '#import <Foundation/Foudation.h>'
            file.puts '@interface %s : NSObject' % cl.className
            cl.methods.each do |fn|
                file.puts '%s(%s) %s' % ['-', fn.returnType, fn.methodName]
                file.puts ''
            end
            file.puts '@end'
        end
        group.new_reference(h_path)
    
        File.open(c_path) do |file|
            file.puts '#import "%s"' % File.basename(h_path)
            file.puts '@implementation %s' % meta.className
            cl.methods.each do |fn|
                file.puts ''
                file.puts '%s(%s) %s' % ['-', fn.returnType, fn.methodName]
                file.puts '{'                
                if fn.returnType == 'NSString*'
                    fn.puts 'return @"";'    
                elsif fn.returnType == 'BOOL'
                    fn.puts 'return YES;'
                elsif fn.returnType == 'void'
                    fn.puts 'return ;'
                elsif fn.returnType == 'int'
                    fn.puts 'return 1;'
                end
                file.puts '}'
            end
            file.puts '@end'
        end
        c_ref = group.new_reference(c_path)
        $proj.targets.each do |target|
            target.source_build_phase.add_file_reference(c_ref, true)
        end 
    end
end

def genJunk(meta)
    meta.groups.each do |gp|
        genDir(gp)
        genCode(gp)
    end
end

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
    if File.exists?(yaml_path)
        $junk = YAML.load(File.open(yaml_path))
    end
    genJunk($junk)
    $proj.save()
end