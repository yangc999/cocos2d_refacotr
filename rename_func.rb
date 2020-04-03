
require 'xcodeproj'
require 'stringio'
require 'yaml'

$proj = nil
$lua = nil
$prefix = 'XB'
$proj_path = '/home/yangc/testconfuse/com.test.confuse/frameworks/runtime-src/proj.ios_mac/com.test.confuse.xcodeproj'

def visit()
    $proj.files.each do |file|
        ext = File.extname(file.path)
        if ext == '.cpp' or ext == '.c'
            path = file.real_path.to_s
            if File.exists?(path)
                buffer = StringIO.new
                find_cls = false
                cls_idx = 0
                File.open(path, 'r').each_line do |line|
                    li = line.chomp
                    if li.include?('tolua_beginmodule')
                        cls = li.scan(/"(.*)"/)[0]
                        if cls
                            $lua['classes'].each do |meta|
                                cls_idx += 1
                                if meta['new'].to_s.eql?(cls[0])
                                    puts 'match class %s' % cls[0]
                                    find_cls = true
                                end
                            end
                        end
                    elsif li.include?('tolua_function')
                        puts 'meet func'
                        puts find_cls
                        if find_cls
                            fn = li.scan(/"(.*)"/)[0][0]
                            puts 'func %s' % fn
                            $lua['classes'][cls_idx-1]['functions'] = Array.new if $lua['classes'][cls_idx-1].has_key?('functions') 
                            sn = '%%' % [$prefix, fn]
                            swp = {'old'=>fn, 'new'=>sn}
                            puts swp.to_s
                            $lua['classes'][cls_idx-1]['functions'] << swp
                            li = li.gsub(fn, sn)
                        end
                    elsif li.include?('tolua_endmodule')
                        find_cls = false
                    end
                    buffer.puts li
                end
                File.open(path, 'w') do |f|
                    f.puts buffer.string
                end
            end
        end
    end
end

puts 'input xcodeproj file path:'
path = gets.chomp
$proj_path = path.length > 0 ? path : $proj_path
if File.exists?($proj_path) and File.directory?($proj_path)
    $proj = Xcodeproj::Project.open($proj_path)
    yaml_path = '%s/lua.yaml' % $proj.main_group.real_path.to_s 
    if File.exists?(yaml_path)
        $lua = YAML.load(File.open(yaml_path))
    end
    visit()
    File.open(yaml_path, 'w') do |f|
        f.puts $lua.to_yaml
    end
end
