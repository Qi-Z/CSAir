a = [['a', 2], ['b',4],['c',3]]
puts(a.sort!{|x, y| y[1] <=> x[1]}.to_s)
h = Hash.new
puts(h.size)
a = "sfsdfsdf"
puts(a[0..-3])