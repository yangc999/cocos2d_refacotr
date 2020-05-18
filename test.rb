re = Regexp.new('[^a-zA-Z0-9]%s[^a-zA-Z0-9]+' % 'gogo')
puts !re.match('gogo ').nil?