require 'json'
require 'launchy' # To open browser

class City
  def initialize(code, name, country, continent, timezone, coordinates, population, region)
    @code = code
    @name = name
    @country = country
    @continent = continent
    @timezone = timezone
    @coordinates = coordinates
    @population = population
    @region = region
  end
  def get_all()
    h = Hash["code"=>@code, "name"=>@name, "country"=>@country, "continent"=>@continent,
             "timezone"=>@timezone, "coordinates"=>@coordinates, "population"=>@population, "region"=>@region]
  end
end

class Node
  def initialize(code, dist)
    @code = code  # seems redundant
    @dist = dist
  end
  def get_dist()
    @dist
  end
end
file = File.read('map_data.json')
data_hash = JSON.parse(file)

city_hash = Hash.new #city_hash uses code as key.
graph = Hash.new #graph uses code as key.
# Extract cities from json file. 48 cities.
# Use code as city ID.
data_hash['metros'].each do |city|

  graph[city['code']] = Hash.new
  city_hash[city['code']] = City. new(city['code'], city['name'], city['country'], city['continent'],
                                      city['timezone'], city['coordinates'], city['population'], city['region'])
  #puts city['code']
end

# Add edges
data_hash['routes'].each do |route|
  graph[route['ports'][0]][route['ports'][1]] =  Node. new(route['ports'][1], route['distance'])
  graph[route['ports'][1]][route['ports'][0]] =  Node. new(route['ports'][0], route['distance'])
end

#puts city_hash
#$count = 0
puts city_hash.size
prompt_exist = true
while prompt_exist do
  puts("\n\n======================")
  puts("1. Get a list of all the cities that CSAir flies to.\n2. Show city info.\n3. Statistical information about CSAir's route network.\nType Q or q to exit.")
  puts("======================")
  option = gets.chomp # User option

  case option
    when "1"
      puts "-: Cites CSAir flies to :"
      city_hash.each do |key, value|
        #$count += 1
        puts value.get_all['name']
      end
    when "2"
      puts "-: Please type in the city name or code:"
      s = gets.chomp.downcase
      flag = false
      city_hash.each do |code, city_class|
        if code.downcase == s || s == city_class.get_all['name'].downcase
          flag = true
          city_class.get_all.each do |k, v|
            puts("#{k} : #{v}")
          end
          puts "\nAll cities accessible from #{city_class.get_all['name']}:"
          graph[city_class.get_all['code']].each do |k, node_class| # k is the code, node_class contains city code and distance.
            puts("#{city_hash[k].get_all["name"]}, #{node_class.get_dist}")
          end
          break
        end
      end # end traversing city_hash
      if flag == false
        puts "-: No city matches your query!"
      end
    when "3"
      puts("-:")
      puts(["a. the longest single flight in the network",
          "b. the shortest single flight in the network",
      "c. the average distance of all the flights in the network",
      "d. the biggest city (by population) served by CSAir",
      "e. the smallest city (by population) served by CSAir",
      "f. the average size (by population) of all the cities served by CSAir",
      "g. a list of the continents served by CSAir and which cities are in them",
      "h. identifying CSAir's hub cities – the cities that have the most direct connections."
           ].join("\n") + "\n\n")
      sub_option = gets.chomp
      case sub_option
        when "a"
          longest = data_hash["routes"][0]["distance"]
          longest_route = data_hash["routes"][0]
          data_hash["routes"].each do |route|
            if longest < route["distance"]
              longest = route["distance"]
              longest_route = route
            end
          end
          puts("#{longest_route["ports"][0]} <---> #{longest_route["ports"][1]}, distance is #{longest}")
        when "b"
          shortest = data_hash["routes"][0]["distance"]
          shortest_route = data_hash["routes"][0]
          data_hash["routes"].each do |route|
            if shortest > route["distance"]
              shortest = route["distance"]
              shortest_route = route
            end
          end
          puts("#{shortest_route["ports"][0]} <---> #{shortest_route["ports"][1]}, distance is #{shortest}")
        when "c"
          total_dist = 0

          data_hash["routes"].each do |route|
            total_dist += route["distance"]
          end
          puts("Average distance is #{total_dist/data_hash["routes"].size}")
        when "d" # Do this messy stuff in case the city hash above has some cities not server by CSAir.
          tmp_key, tmp_value = city_hash.first
          biggest = tmp_value.get_all["population"]
          biggest_city_code = tmp_key
          #puts(biggest)
          #puts(biggest_city_code)

          data_hash["routes"].each do |route|
            city_code = route["ports"][0]
            if biggest < city_hash[city_code].get_all["population"]
              biggest = city_hash[city_code].get_all["population"]
              biggest_city_code = city_code

            end
            city_code = route["ports"][1]
            if biggest < city_hash[city_code].get_all["population"]
              biggest = city_hash[city_code].get_all["population"]
              biggest_city_code = city_code
            end
          end


          puts("The biggest city by population served by CSAir is #{city_hash[biggest_city_code].get_all["name"]} with population #{biggest}")
        when "e"
          tmp_key, tmp_value = city_hash.first
          smallest = tmp_value.get_all["population"]
          smallest_city_code = tmp_key
          #puts(biggest)
          #puts(biggest_city_code)

          data_hash["routes"].each do |route|
            city_code = route["ports"][0]
            if smallest > city_hash[city_code].get_all["population"]
              smallest = city_hash[city_code].get_all["population"]
              smallest_city_code = city_code

            end
            city_code = route["ports"][1]
            if smallest > city_hash[city_code].get_all["population"]
              smallest = city_hash[city_code].get_all["population"]
              smallest_city_code = city_code
            end
          end


          puts("The smallest city by population served by CSAir is #{city_hash[smallest_city_code].get_all["name"]} with population #{smallest}")

        when "f"
          total_pop = 0
          city_hash.each do |k, v|
            total_pop += v.get_all["population"]
          end
          puts("Average population is #{total_pop/city_hash.size}")
        when "g"
          continent_hash = Hash[] # key is continent, value is an array containing cities
          city_hash.each do |k, v|
            continent = v.get_all["continent"]
            if continent_hash.has_key?(continent)
              continent_hash[continent].push(v.get_all["name"])
            else
              continent_hash[continent] = Array.new
              continent_hash[continent].push(v.get_all["name"])
            end
          end
          continent_hash.each do |k, v|
            # I haven't consider duplicates of city names here.

            puts("#{k}: #{v.join(", ")}")
          end
        when "h"
          hub_cities = Array.new
          max_direct_connect = graph.values[0].size
          puts(max_direct_connect)
          # figure out max connect
          graph.each do |k, v| # key is city code, v is a hash table of (city code, Node) pairs
            if max_direct_connect < v.size
              max_direct_connect = v.size
            end
          end
          # now check which cities have the max direct connections
          graph.each do |k, v|
            if v.size == max_direct_connect
              hub_cities.push(k)
            end
          end
          puts("Hub cities are: "+hub_cities.join(", ")+"\n")
        else
          puts("Invalid option!")
      end
    when "q", "Q"
      prompt_exist = false
    else
      puts "Unacceptable option!"
  end
end

puts("Opening browser to show routes for you ...")
route_arr = Array.new
url = "http://www.gcmap.com/mapui?P="

data_hash["routes"].each do |route|
  route_str = route["ports"][0] + "-" + route["ports"][1]
  route_arr.push(route_str)
end
url += route_arr.join(",+")
Launchy.open(url)

#puts $count
#puts graph




