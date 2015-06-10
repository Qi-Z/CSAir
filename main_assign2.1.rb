require 'json'
require 'launchy' # To open browser

# DEBUG tips:
# to use method .each, make sure it's not nilObject
def print_menu_1()
  puts("\n\n======================")
  puts("1. Get a list of all the cities that CSAir flies to.\n2. Show city info.\n3. Statistical information about CSAir's route network.")
  puts("4. Do some editing.")
  puts("Type Q or q to exit (without saving). Type & to save current map. ")
  puts("Type Q& or q& to exit and save. ")
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

# Take in city info given by user in this format:
# code#name#country#continent#timezone#coordinate1#coordinate2#population#region
# Do sanity-checking.
# Return an array: [city object, error_info_array]
def verify_city_info(s)

  errors = ['Info not enough! ', 'Continent is wrong! ', 'Timezone not in range[-12, 14] or not number!',
            'Population should be non-negative integer! ', 'Region should be a number! ',
            'Coordinates wrong, N/S[0-90], E/W[0-180]! ']
  info_arr = s.split('#')
  verified = true
  error_info = Array.new # This contains actually errors.
  if info_arr.size != 9
    return [nil, [errors[0]]]
  end
  info_arr.map!{|e|   # map! makes it possible to change elements in place.
    e.rstrip.lstrip
  }
  if info_arr.include?("")
    verified = false
    error_info.push(errors[0])
  else
    code = info_arr[0].upcase
    name = info_arr[1].split.map(&:capitalize).join(' ')
    country = info_arr[2].split.map(&:capitalize).join(' ')
    timezone = info_arr[4]
    longit = info_arr[5].downcase
    lat = info_arr[6].downcase
    pop = info_arr[7]
    region = info_arr[8]
    coordinates = Hash.new()
    range = {'s'=>[0, 90], 'n'=>[0,90], 'e'=>[0, 180],'w'=>[0, 180]}
    continent = info_arr[3].downcase
    # Based on Wikipedia page about continents. One model is 7-continent one. I use it.
    if ["africa", "europe", "asia", "north america", "south america", "antarctica", "australia"].include?(continent)
      continent = continent.split.map(&:capitalize).join(' ') # capitalize every word
    else
      verified = false
      error_info.push(errors[1])
    end
    if is_num(timezone) && timezone.to_f >= -12 && timezone.to_f <= 14
      timezone = timezone.to_f
    else
      verified = false
      error_info.push(errors[2])
    end
    if is_int(pop) && pop.to_i >= 0
      pop = pop.to_i
    else
      verified = false
      error_info.push(errors[3])
    end
    if is_int(region)
      region = region.to_i
    else
      verified = false
      error_info.push(errors[4])
    end
    if ['ne','en','nw','wn','se','es','sw','ws'].include?((longit[0]+lat[0]).downcase)
      if is_num(longit[1..-1]) && is_num(lat[1..-1])
        if (longit[1..-1].to_f <= range[longit[0]][1]) && (longit[1..-1].to_f >= range[longit[0]][0]) && (lat[1..-1].to_f <= range[lat[0]][1]) && (lat[1..-1].to_f >= range[lat[0]][0])
          coordinates[longit[0].upcase] = longit[1..-1].to_f
          coordinates[lat[0].upcase] = lat[1..-1].to_f
        else
          verified = false
          error_info.push(errors[-1])
        end
      else
        verified = false
        error_info.push(errors[-1])
      end
    else
      verified = false
      error_info.push(errors[-1])
    end
    info_arr = [code, name, country, continent, timezone, coordinates, pop, region ]
  end
  error_info.uniq! #remove duplicate error messages
  if verified

    city = City.new(*info_arr)
    return [city, []]
  else
    return [nil, error_info]
  end

end

# Take in airline class for the graph, data_hash for data source part.
# Save these hash tables to disk.
def save_json_to_disk(airline, data_hash)
  File.open("temp.json","w") do |f|
    h = Hash.new
    city_hash = airline.get_city_hash
    graph = airline.get_graph
    h['data sources'] = data_hash['data sources']

    # extract city info from city_hash
    c_arr = Array.new
    city_hash.each do |code, city_object|
      c = city_object.get_all
      c_arr.push(c)
    end
    h['metros'] = c_arr

    #route info
    route_arr = Array.new
    graph.each do |code, hash_table|
      hash_table.each do |c, node|
        route_arr.push({"ports"=>[code, c], "distance"=> node.get_dist})
      end
    end
    h['routes'] = route_arr
    f.write(JSON.pretty_generate(h))
  end
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
  def initialize(data_hash, double_edge = true) # Take in a Hash table of the json file.
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

      # This line assumes given json file implicitly indicates double edge.
      if double_edge
        @graph[route['ports'][1]][route['ports'][0]] =  Node. new(route['ports'][0], route['distance'])
      end
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

  # Take in a string from#to#distance. From and To are codes.
  def add_route_by_string(s)
    arr = s.split('#')
    arr.map!{|e| # Remove preceding and trailing spaces
      e.lstrip.rstrip
    }

    if arr.size == 3
      if arr.include?("")
        puts("Not enough info! Adding failed! ")
      else
        f = search_city(arr[0]) # must be in city_hash in order for the route to be added.
        t = search_city(arr[1])
        d = arr[2]
        if f != nil && t != nil && is_num(d)
          d = d.to_f
          node = Node.new(f.get_all['code'], d)
          @graph[f.get_all['code']][t.get_all['code']] = node
          puts("Route added!")
        else
          puts("Incorrect format or city does not exists! ")

        end
      end
    else
      puts("Not enough info! Adding failed! ")

    end

  end

  # Edit a city. City code cannot be changed.
  # info_str is a complete info string used in verify_city_info.
  def update_city(city_code, info_str)

    if search_city(city_code) == nil
      puts("No such city")
    else
      result = verify_city_info(info_str)
      if result[0] != nil
        @city_hash[result[0].get_all['code']] = result[0]
        puts("#{city_code} updated! ")
      else
        puts("Failed!"+ result[1].to_s)
      end
    end
  end

  # Return a city info separated by '#'
  def city_info_string(city_code)
    str = Array.new
    city = search_city(city_code)
    if city == nil
      return nil
    else
      city.get_all.each do |k, v|
        if v.is_a?(Hash) # formatting coordinates
          str.push(v.keys[0]+v.values[0].to_s+'#'+v.keys[1]+v.values[1].to_s)
        else
          str.push(v)
        end

      end
      return str.join("#")
    end
  end

  # Get info of a route
  # Take in a string, a list of city codes separated by comma.
  # Return [false, {}]   OR  [true, {total_dist, cost, time}]
  def get_route_info(s)
    # string cleaning
    city_code_arr = s.split(',')
    if city_code_arr.size < 2
      puts("Illegal route! Need at least 2 cities!")
      return [false, {}]
    end
    city_code_arr.map!{|c|
      c.lstrip.rstrip
    }
    all_city_exist = true
    city_code_arr.each do |code|
      if search_city(code) == nil
        all_city_exist = false
        break
      else
        next
      end
    end

    if all_city_exist
      edge_arr = Array.new   #[[code of from, code of to], [], ..., []]
      # route parsing: basically change [SCL, LAX, MEX] to [[SCL, LAX], [LAX, MEX]]
      # for every code in array except the 1st and last codes.

      city_code_arr[1..-2].each do |code|
        code_ = search_city(code).get_all['code']
        edge_arr.push(code_)
        edge_arr.push(code_)
      end
      # prepend and append 1st and last code to edge_arr
      edge_arr.unshift(search_city(city_code_arr[0]).get_all['code'])
      edge_arr.push(search_city(city_code_arr[-1]).get_all['code'])
      if edge_arr.size % 2 != 0
        puts("Something wrong in route parsing!")
        return [false,{}]
      else
        edge_arr = edge_arr.each_slice(2).to_a
      end
      # start check each route in the graph
      total_dist = 0
      cost = 0
      time = 0
      puts(edge_arr)
      edge_arr.each do |route| # route is an array of 2 elements : [from, to]
        from = route[0]
        to = route[1]
        puts("#{from} -> #{to}:  #{search_city(to).get_all['code']}")
        if @graph.has_key?(from)
          if @graph[from].has_key?(to)
            total_dist += @graph[from][to].get_dist
          else
            puts("No flight from #{from} to #{to}")
          end
        else
          puts("No flight from #{from}")
          return [false,{}]
        end
      end
      return [true, {"total_dist"=>total_dist, "cost"=>cost, "time"=>time}]
    else

      puts("Not all cities are in our city_hash! Please check code spelling and make sure all cities have been recorded by us. ")
      return [false, {}]
    end

  end
end

file = File.read('map_data.json')
data_hash = JSON.parse(file)

airline = Airline.new(data_hash)
puts(airline.get_route_info("scl, LIM, mex").to_s)
#puts(airline.get_graph)
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
              res = verify_city_info(s)
              if res[0] == nil
                puts("Fail to add city: ")
                puts(res[1].to_s)
              else
                airline.add_city(res[0])
                puts("City added!")
              end

            end
          when "4"
            while true do
              puts("# Type in route in this format code#code#distance: ")
              s = gets.chomp
              if s == '<'
                break
              end
              airline.add_route_by_string(s)
            end
          when "5"
            while true do
              puts("Type in city CODE of the city to be edited: #")
              s = gets.chomp
              if s == '<'
                break
              end
              city = airline.search_city(s)
              if city == nil
                puts("No such city! ")
              else
                while true do
                  puts("========\nIn this format: name#country#continent#timezone#coordinate1#coordinate2#population#region")
                  puts("\'>\' to show current info")
                  info = gets.chomp
                  if info == '<'
                    break
                  elsif info == '>'
                    puts("current info: #{airline.city_info_string(s)}")
                    next
                  end
                  airline.update_city(s, s+'#'+info)
                end
              end
            end
          else
            puts("Invalid option!")
        end
      end
    when '&'
      save_json_to_disk(airline, data_hash)
      puts("File saved!")
    when 'Q&', "q&"
      save_json_to_disk(airline, data_hash)
      puts("File saved!")
      prompt_exist = false
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






