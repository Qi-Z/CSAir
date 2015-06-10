city_code_arr= [1,2,3, 4]
edge_arr = Array.new

city_code_arr[1..-2].each do |code|
  edge_arr.push(code)
  edge_arr.push(code)
end
# prepend and append 1st and last code to edge_arr
edge_arr.unshift(city_code_arr[0])
edge_arr.push(city_code_arr[-1])
if edge_arr.size % 2 != 0
  puts("Something wrong in route parsing!")

else
  edge_arr = edge_arr.each_slice(2).to_a
  puts(edge_arr.to_s)
end
