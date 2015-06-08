require 'json'
require 'launchy' # To open browser

# DEBUG tips:
# to use method .each, make sure it's not nilObject
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

def print_menu_3()
  puts(
  ["1. Remove a city",
  "2. Remove a route",
  "3. Add a city, including all its necessary information",
  "4. Add a route, including all its necessary information",
  "5. Edit an existing city"].join("\n")+"\n\n"
  )
end

def is_int(s)
  /\A[-+]?\d+\z/ === s
end

def is_num(s)
  flag = true
  if s.split('.').size == 3
    return false
  end
  s.split('.').each do |i|
    if !is_int(i)
      flag = false
    end
  end
  return flag
end

# Take in an array containing all necessary info about a city.
# Parameter type: [code 0, name 1, country 2, continent 3, timezone 4, coordinates(a hash table) 5, population 6, region 7]
# This parameter is the same as params of the constructor of city class.
# Do SANITY-CHECKING. Return a city object is it passes the checking, otherwise return nil.
def create_city(info_arr)
  puts(info_arr.class)
  if info_arr.include?("") # check if empty string is provided
    puts("Some info is not provided! Creating Failed!")
  # Based on Wikipedia page about continents. One model is 7-continent one. I use it.
  elsif !["africa", "europe", "asia", "north america", "south america", "antarctica", "australia"].include?(info_arr[3])
    puts("The continent you provided is incorrect! Creating Failed!")
  #  Coordinated Universal Time (UTC), from the westernmost (−12:00) to the easternmost (+14:00).
  elsif info_arr[4] < -12 || info_arr[4] > 14
    puts("Timezone not in range [-12, 14]! Creating Failed!")

  else
    info_arr[0].upcase!
    info_arr[1] = info_arr[1].split.map(&:capitalize).join(' ') # capitalize each word
    info_arr[2] = info_arr[2].split.map(&:capitalize).join(' ') # capitalize each word
    info_arr[3] = info_arr[3].split.map(&:capitalize).join(' ')

    return City.new(*info_arr)
  end
    nil
end
class City
  # Notice that coordinates is a hash table
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
    3. city_hash, hash table (code, city_class)
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
  # *     In case one city's code is the same as another city's name or vice verse,
  # *     might need to change this function to accept code only.
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

  # Take in city code or city name
  # Remove the city both from city_hash and the graph

  def remove_city(s)
    city = search_city(s)
    if city == nil
      puts("No such city! (It's been removed or mispelled)")
    else
      @city_hash.delete(city.get_all['code'])
      # Delete this city from the graph and all routes related to this city
      @graph.delete(city.get_all['code'])
      @graph.each do |code, h|
        h.delete(city.get_all['code'])
      end
      puts("#{city.get_all['name']} is removed!")
    end
  end

  # Take in two city codes or names
  # Remove the route if it exists. Otherwise, output errors.
  def remove_route(from, to)
    c1 = search_city(from) # search_city search in city_hash, such city might not exist in the graph.
    c2 = search_city(to)
    if c1 != nil && c2 != nil
      if @graph.has_key?(c1.get_all['code'])
        if @graph[c1.get_all['code']].has_key?(c2.get_all['code'])
          @graph[c1.get_all['code']].delete(c2.get_all['code'])
          puts("Route #{c1.get_all['name']} to #{c2.get_all['name']} is removed!")
        else
          puts("No such route! ")
        end
      else
        puts("No such route! ")
      end
    else
      puts("Cannot find the city you query! ")
    end
  end

  def add_city(city)

    if city != nil
      if @city_hash.has_key?(city.get_all['code'])
        puts("The city info you provide is ALREADY in our database, we will UPDATE that city.")
      end
      @city_hash[city.get_all['code']] = city
    else
      puts("City info INCORRECT! Please check!")
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
          res = airline.cities_directly_reached_from(s)
          if res != nil
            res.each do |code, node|
              puts("#{city_hash[code].get_all["name"]}, #{node.get_dist}")
            end
            puts("\n\n")
          else
            puts("No city accessible from #{city.get_all['name']}\n\n\n")
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

    when "4"

      while true do
        print_menu_3
        sub_option = gets.chomp
        if sub_option == "<"
          break
        end
        case sub_option
          when "1"
            while true do
              puts("\nType in the city (code or name) to be removed: \n Type \'<\' to go back")
              s = gets.chomp
              if s == "<"
                break
              end
              airline.remove_city(s)
            end
          when "2"
            # Assume no city code or name contains '#'
            puts("\nType in two cities (code or name), separated by a #: ")
            s = gets.chomp
            arr = s.split('#')
            if arr.size == 2
              #r/lstrip is used to remove trailing/preceding spaces
              airline.remove_route(arr[0].rstrip.lstrip, arr[1].rstrip.lstrip)
            else
              puts("Unable to remove route, please provide two cities AND use # to separate them!")
            end

          when "3"
            while true do
              puts("\n==========\nPlease provide all info of the city:\n
                  code#name#country#continent#timezone#coordinate1#coordinate2#population#region")
              s = gets.chomp
              if s == "<"
                break
              elsif s == "+"
                puts("e.g a#b#c#asia#9#N45#W35#2000#1\n")
                next
              end
              info_arr = s.split('#')
              if info_arr.size == 9
                info_arr.map!{|e|   # map! makes it possible to change elements in place.
                  e.rstrip.lstrip
                }
                timezone = info_arr[4]
                longit = info_arr[5].downcase
                lat = info_arr[6].downcase
                pop = info_arr[7]
                region = info_arr[8]
                coordinates = Hash.new()
                range = {'s'=>[0, 90], 'n'=>[0,90], 'e'=>[0, 180],'w'=>[0, 180]}
                if info_arr.include?("")
                  puts("Some info is not provided! Adding failed!")
                  next
                end

                if is_num(timezone)
                  timezone = timezone.to_f
                else
                  puts("Timezone incorrect! Adding failed!")
                  next
                end

                if is_int(pop) && pop.to_i >= 0
                  pop = pop.to_i
                else
                  puts("Population is not string or it's negative or it's float! Adding failed!")
                  next
                end

                if !is_num(region)
                  puts("Region is not number! Adding failed!")
                  next
                else
                  region = region.to_i
                end

                if ['ne','en','nw','wn','se','es','sw','ws'].include?((longit[0]+lat[0]).downcase)
                  if is_num(longit[1..-1]) && is_num(lat[1..-1])
                    if (longit[1..-1].to_f <= range[longit[0]][1]) && (longit[1..-1].to_f >= range[longit[0]][0]) && (lat[1..-1].to_f <= range[lat[0]][1]) && (lat[1..-1].to_f >= range[lat[0]][0])
                      coordinates[longit[0].upcase] = longit[1..-1].to_f
                      coordinates[lat[0].upcase] = lat[1..-1].to_f
                    else
                      puts("coord wrong range! Adding failed!")
                      next
                    end
                  else
                    puts("coordinate incorrect! Adding failed!")
                    next


                  end
                else
                  puts("coordinate incorrect! Adding failed!")
                  next
                end
                airline.add_city(create_city(info_arr[0..3]+[timezone, coordinates, pop, region]))
              else
                puts("Not enough info, Adding Failed!\n")
                next
              end

            end
          when "4"
          when "5"
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






