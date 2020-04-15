#! /usr/bin/ruby

require 'xcodeproj'
require 'pathname'

$proj = nil
$proj_path = '/home/yangc/testconfuse/com.test.confuse/frameworks/runtime-src/proj.ios_mac/com.test.confuse.xcodeproj'

if ARGV[0] != nil
    $proj_path = ARGV[0]
else
    puts 'input xcodeproj file path:'
    path = gets.chomp
    $proj_path = path.length > 0 ? path : $proj_path    
end

if File.exists?($proj_path) and File.directory?($proj_path)
    $proj = Xcodeproj::Project.open($proj_path)
    dst_path = $proj.main_group.real_path.to_s
    src_path = Pathname.new(File.dirname(__FILE__)).realpath
    src = '%s/stub.h' % src_path
    dst = '%s/stub.h' % dst_path
    FileUtils.cp(src, dst)
    $proj.main_group.new_reference(dst)
    $proj.save()
end