
require 'xcodeproj'
require 'stringio'

$proj = nil
$proj_path = '/home/yangc/testconfuse/com.test.confuse/frameworks/runtime-src/proj.ios_mac/com.test.confuse.xcodeproj'

def add_comment(file)
    path = file.real_path.to_s
    buffer = StringIO.new
    File.open(path, 'r').each_line do |line|
        li = line.chomp
        buffer.puts li
        if li[li.length-1] == ';'
            for i in 0..rand(4) do
                buffer.puts '// added comment'
            end
        end
    end
    File.open(path, 'w') do |f|
        f.puts buffer.string 
    end
end

$proj = nil
puts 'input xcodeproj file path:'
path = gets.chomp
$proj_path = path.length > 0 ? path : $proj_path
if File.exists?($proj_path) and File.directory?($proj_path)
    $proj = Xcodeproj::Project.open($proj_path)
    $proj.files.each do |file|
        ext = File.extname(file.display_name)
        puts file.display_name
        if ext == '.h' or ext == '.hpp' or ext == '.c' or ext == '.cpp' or ext == '.m' or ext == '.mm'
            puts 'deal'
            add_comment(file)
        end
    end
    $proj.save()
end