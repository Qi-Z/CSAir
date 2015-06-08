require 'json'
require 'launchy' # To open browser

def print_menu_1()
  puts("\n\n======================")
  puts("1. Get a list of all the cities that CSAir flies to.\n2. Show city info.\n3. Statistical information about CSAir's route network.")
  puts("4. Do some editing.")
  puts("Type Q or q to exit.")
  puts("======================")
  puts("# ")
end

def print_menu_2()
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
end
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

class Airline
=begin
  parameters: 1. graph, which is a hash table with [key being city code, value being another hash table]
      which has [key of city code and value of a Node object].
    2. original_data, the hash table of the original json file.
    3. city_hash, hash table (code, )
=end
  def initialize(data_hash) # Take in a Hash table of the json file.
    @graph = Hash.new
    @city_hash = Hash.new

    data_hash['metros'].each do |city|

      @graph[city['code']] = Hash.new
      @city_hash[city['code']] = City. new(city['code'], city['name'], city['country'], city['continent'],
                                          city['timezone'], city['coordinates'], city['population'], city['region'])
      #puts city['code']
    end
    # Add edges, for assignment 2.0. [SCL, LAX] means both two directions.
    data_hash['routes'].each do |route|
      @graph[route['ports'][0]][route['ports'][1]] =  Node. new(route['ports'][1], route['distance'])
      @graph[route['ports'][1]][route['ports'][0]] =  Node. new(route['ports'][0], route['distance'])
    end
  end

  # Return the graph
  def get_graph()
    return @graph
  end

  # Return city hash table which contains all cities in the database, not necessarily served by CSAir.
  def get_city_hash()
    return @city_hash
  end

  # Return an array of codes of cities that CSAir flies to. And print them.
  def get_cities_reached()
    cities = Array.new
    @graph.each do |k, v| # k: city_code, v: hash table of (city_code, Node).
      v.each do |city_code, node|
        cities.push(city_code)
      end
    end
    cities = cities.uniq # remove duplicates
    return cities
  end

  # Take in a string which can be either code or name. Search in city_hash
  # Return a city class that matches the code or name.
  def search_city(s)
    @city_hash.each do |code, city_class|
      if code.downcase == s.downcase || s.downcase == city_class.get_all['name'].downcase
        return city_class
      end
    end
    return nil
  end

  # Take in a string which can be either code or name.
  # Return a hash table of (city_code, Node class)
  def cities_directly_reached_from(s)
    city = search_city(s)
    if city == nil
      puts("No such city!")
    else
      return @graph[city.get_all['code']]

    end
  end

end

file = File.read('map_data.json')
data_hash = JSON.parse(file)

airline = Airline.new(data_hash)

# city_hash = Hash.new #city_hash uses code as key.
# graph = Hash.new #graph uses code as key.
# # Extract cities from json file. 48 cities.
# # Use code as city ID.
# data_hash['metros'].each do |city|
#
#   graph[city['code']] = Hash.new
#   city_hash[city['code']] = City. new(city['code'], city['name'], city['country'], city['continent'],
#                                       city['timezone'], city['coordinates'], city['population'], city['region'])
#   #puts city['code']
# end

# # Add edges
# data_hash['routes'].each do |route|
#   graph[route['ports'][0]][route['ports'][1]] =  Node. new(route['ports'][1], route['distance'])
#   graph[route['ports'][1]][route['ports'][0]] =  Node. new(route['ports'][0], route['distance'])
# end


prompt_exist = true

#  begin with #: to remind user to type something.
#  begin with "- :"  : to show user results.
while prompt_exist do
  print_menu_1
  option = gets.chomp # User option

  case option
    when "1"
      puts(airline.get_cities_reached.join(", "))
    when '2'
      while true do
        puts "Please type in the city name or code: ('<' to go back to last menu)\n# "
        s = gets.chomp.downcase
        if s == '<'
          break
        end
        city = airline.search_city(s)
        if city == nil
          puts "- : No Match!"
        else
          puts("- :")
          city.get_all.each do |k, v|
            puts("#{k} : #{v}")

          end
          puts "\nAll cities accessible from #{city.get_all['name']}:"
          city_hash = airline.get_city_hash()
          airline.cities_directly_reached_from(s).each do |code, node|
            puts("#{city_hash[code].get_all["name"]}, #{node.get_dist}")
          end
        end
      end


    when "3"
      print_menu_2
      while true do
        sub_option = gets.chomp
        if sub_option == "<"
          break
        end
        case sub_option
        when "a"
          g = airline.get_graph()
          flight_arr = Array.new
          g.each do |code, h|
            h.each do |c, n| # code and Node
            flight_arr.push([code, c, n.get_dist()])
            end
          end

          max = -1
          flight_arr.each do |e| # find the max
            if max < e[2]
              max = e[2]
            end
          end
          # check how many flights have this max distance.
          res = Array.new
          flight_arr.each do |e|
            if max == e[2]
              res.push([e[0],e[1]])
            end
          end

          puts("Longest single flight is: ")
          res.each do |e|
            puts(e[0]+" --> "+e[1]+", distance is #{max}")
          end



        when "b"
          g = airline.get_graph()
          flight_arr = Array.new
          g.each do |code, h|
            h.each do |c, n| # code and Node
              flight_arr.push([code, c, n.get_dist()])
            end
          end

          min = Float::INFINITY
          flight_arr.each do |e| # find min
            if min > e[2]
              min = e[2]
            end
          end
          # check how many flights have this min dist.
          res = Array.new
          flight_arr.each do |e|
            if min == e[2]
              res.push([e[0], e[1]])
            end
          end
          puts("Shortest single flight is: ")
          res.each do |e|
            puts(e[0]+" --> "+e[1]+", distance is #{min}")
          end

        when "c"
          total_dist = 0
          num_routes = 0
          g = airline.get_graph()

          g.each do |code, h|
            h.each do |c, n| # code and Node
              total_dist += n.get_dist()
              num_routes += 1
            end
          end
          puts("Average distance is #{total_dist/num_routes}")
        when "d" # Do this messy stuff in case the city hash above has some cities not server by CSAir.

          code_arr = airline.get_cities_reached
          pop_arr = Array.new
          code_arr.each do |code|
            city = airline.search_city(code)
            pop_arr.push([city.get_all['code'], city.get_all['population']])
          end
          res = Array.new
          max = -1
          pop_arr.each do |e| # find max
            if max < e[1]
              max = e[1]
            end
          end
          pop_arr.each do |e|
            if max == e[1]
              res.push(e[0])
            end
          end
          puts("The biggest city by population served by CSAir is: ")
          res.each do |e|
            puts(" #{e} with population #{max}")
          end
        when "e"
          code_arr = airline.get_cities_reached
          pop_arr = Array.new
          code_arr.each do |code|
            city = airline.search_city(code)
            pop_arr.push([city.get_all['code'], city.get_all['population']])
          end
          res = Array.new
          min = Float::INFINITY
          pop_arr.each do |e| # find max
            if min > e[1]
              min = e[1]
            end
          end
          pop_arr.each do |e|
            if min == e[1]
              res.push(e[0])
            end
          end
          puts("The smallest city by population served by CSAir is: ")
          res.each do |e|
            puts(" #{e} with population #{min}")
          end
        when "f"
          total_pop = 0
          code_arr = airline.get_cities_reached
          code_arr.each do |code|
            city = airline.search_city(code)
            total_pop += city.get_all['population']
          end
          puts("Average population is #{total_pop/code_arr.size}")
        when "g"
          continent_hash = Hash[] # key is continent, value is an array containing cities
          code_arr = airline.get_cities_reached
          code_arr.each do |code|
            city = airline.search_city(code)
            continent = city.get_all['continent']
            if continent_hash.has_key?(continent)
              continent_hash[continent].push(city.get_all['code'])
            else
              continent_hash[continent] = [city.get_all['code']]
            end
          end
          puts("Continents served by CSAir are: ")
          continent_hash.each do |k, v|
            puts("#{k}:")
            puts(v)
          end

        when "h"
          # Typically the hub city is the city with the most flights out, you don't have to do it by continent.
          # Usually, people print the top 3 "hub cities" and their number of outbound flights. --- From sp15 piazza.
          graph = airline.get_graph
          res = Array.new
          graph.each do |code, h|
            res.push([code, h.size])

          end
          res.sort!{|x, y| y[1] <=> x[1]} # Sort the array in-place by number of outgoing flights.

          puts("Top 3 Hub cities are: ")
          if res.size >= 3
            puts("#{res[0].to_s}, #{res[1].to_s} and  #{res[2].to_s}")
          else
            str = ""
            res.each do |e|
              str += "#{e.to_s}, "
            end
            str = str[0..-3] # delete one comma and one blank space.
            puts(str)
          end
        else
          puts("Invalid option!")
      end
      end
    when "q", "Q"
      prompt_exist = false
    else
      puts "Unacceptable option!"
  end
end

#Show on map.
puts("Opening browser to show routes for you ...")
route_arr = Array.new
url = "http:/www.gcmap.com/mapui?P="

graph = airline.get_graph
graph.each do |c, h|
  h.each do |code, node|
    route_arr.push(c+'-'+code)
  end
end

url += route_arr.join(",+")
Launchy.open(url)






