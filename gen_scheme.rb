#! /usr/bin/ruby

require 'xcodeproj'
require 'yaml'
require 'json'
require 'open-uri'

$arr = nil
$queryUrl = 'http://fanyi.youdao.com/openapi.do?keyfrom=youdaoci&key=694691143&type=data&doctype=json&version=1.1&q='
$dictPath = '/usr/share/dict/words'
$scheme = Hash.new
$groupSize = 2
$classSize = 2
$methodSize = 2
$rets = ['NSString*', 'void', 'int', 'BOOL']

File.open($dictPath, 'r') do |f|
    $arr = f.readlines()
end

def queryWord(w)
    sleep 1
    puts 'query ' + w.to_s
    URI.open($queryUrl + w.to_s) do |resp|
        puts resp.string
        js = JSON.parse(resp.string)
        if js and js['basic'] and js['basic']['explains']
            return js['basic']['explains']
        else
            return []
        end
    end
end

def randomWord()
    begin
        idx = rand(0..$arr.length)
        word = $arr[idx].chomp().gsub('\'s', '')
    end while word.match?(/[^a-zA-Z]/)
    return word.downcase()
end

def randomNoun()
    isNoun = false
    w = nil
    while !isNoun do
        w = randomWord()
        ts = queryWord(w)
        ts.each do |m|
            if m[0..1] == 'n.'
                isNoun = true
                break
            end
        end
    end
    return w
end

def randomVerb()
    isVerb = false
    w = nil
    while !isVerb do
        w = randomWord()
        ts = queryWord(w)
        ts.each do |m|
            if m[0..1] == 'v.' or m[0..2] == 'vt.' or m[0..2] == 'vi.'
                isVerb = true
                break
            end
        end
    end
    return w
end

def randomAdj()
    isVerb = false
    w = nil
    while !isVerb do
        w = randomWord()
        ts = queryWord(w)
        ts.each do |m|
            if m[0..3] == 'adj.'
                isVerb = true
                break
            end
        end
    end
    return w
end

#File.open($dictPath, 'r') do |f|
#    arr = f.readlines()
#    groupNum = rand(0..10)
#    (0..groupNum).each do
#        idx = rand(0..arr.length)
#        $groups << arr[idx].chomp().downcase().gsub('\'s', '')
#    end
#    classNum = rand(0..20)
#    (0..classNum).each do
#        idx = rand(0..arr.length)
#        $classes << arr[idx].chomp().downcase().gsub('\'s', '')
#    end
#    methodNum = rand(0..5)
#    (0..methodNum).each do
#        idx = rand(0..arr.length)
#        $methods << arr[idx].chomp().downcase().gsub('\'s', '')
#    end
#end

$scheme['groups'] = Array.new
(0..$groupSize).each do |gi|
    $scheme['groups'][gi] = Hash.new
    $scheme['groups'][gi]['groupName'] = randomNoun()
    $scheme['groups'][gi]['classes'] = Array.new
    (0..$classSize).each do |ci|
        $scheme['groups'][gi]['classes'][ci] = Hash.new
        $scheme['groups'][gi]['classes'][ci]['className'] = randomNoun()
        $scheme['groups'][gi]['classes'][ci]['methods'] = Array.new
        (0..$methodSize).each do |mi|
            $scheme['groups'][gi]['classes'][ci]['methods'][mi] = Hash.new
            $scheme['groups'][gi]['classes'][ci]['methods'][mi]['returnType'] = $rets[rand(0..$rets.length()-1)]
            $scheme['groups'][gi]['classes'][ci]['methods'][mi]['methodName'] = randomNoun()
        end
    end
end

puts $scheme.to_yaml

#if ARGV[0] != nil
#    $proj_path = ARGV[0]
#else
#    puts 'input xcodeproj file path:'
#    path = gets.chomp
#    $proj_path = path.length > 0 ? path : $proj_path    
#end
#
#if File.exists?($proj_path) and File.directory?($proj_path)
#    $proj = Xcodeproj::Project.open($proj_path)
#    yaml_path = '%s/junk.yaml' % $proj.main_group.real_path.to_s
#    File.open(yaml_path, 'a+') do |f|
#        f.puts $scheme.to_yaml
#    end
#end
