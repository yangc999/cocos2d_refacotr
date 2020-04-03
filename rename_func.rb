
require 'xcodeproj'
require 'stringio'
require 'yaml'

$proj = nil
$proj_path = '/home/yangc/testconfuse/com.test.confuse/frameworks/runtime-src/proj.ios_mac/com.test.confuse.xcodeproj'

puts 'input xcodeproj file path:'
path = gets.chomp
$proj_path = path.length > 0 ? path : $proj_path
if File.exists?($proj_path) and File.directory?($proj_path)
    $proj = Xcodeproj::Project.open($proj_path)
    yaml_path = '%s/lua.yaml' % $proj.main_group.real_path.to_s 
    if File.exists?(yaml_path)
        yaml = YAML.load(File.open(yaml_path))
        gen_lua(yaml)
    end
end
