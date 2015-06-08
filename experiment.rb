
  def is_i(s)
    /\A[-+]?\d+\z/ === s
  end
  def is_num(s)
    flag = true
    if s.split('.').size == 3
      return false
    end
    s.split('.').each do |i|
      if !is_i(i)
        flag = false
      end
    end
    return flag
  end


puts(is_num("2.2.4"))
puts("2.2...".to_f)
puts("===========")
['ne','en','nw','wn','se','es','sw','ws'].each do |s|
  puts(['en','sw', 'nw', 'es'].include?(s.downcase.chars.sort.join))
end

