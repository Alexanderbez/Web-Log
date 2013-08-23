# CMSC 330 / Summer 2012 / Project 1
# Student: Alexander Bezobchuk

  mode = ARGV[0]  # Get the mode
  file = ARGV[1]  # Get the file name

# Validate mode

if mode == "validate" then

  IO.foreach(file) do |log_entry|
    
    spaces = (log_entry.scan(/\s/)).length
    
    # Correct log entry should have 10 spaces, no more no less
    if spaces != 10
      puts "no"
      exit
    end
    
    # The various lines of code below use generic regex to extract portions
    # of the line entry in the log, later to be examined.
    ip_re = log_entry[/^\d+[.]+\d+[.]+\d+[.]+\d+\s+/]
    
    if ip_re != nil
      ip_re.gsub!(" ","")
    end
    
    hyphen_re = log_entry[/\d\s+\D\s+/]

    if hyphen_re != nil
      hyphen_re.gsub!(/\d/,"")
      hyphen_re.gsub!(" ","")
    end
    
    date_re = log_entry[/\[(.*)\]/]
    bytes_re = log_entry[/-?\d*$/]
    request_re = log_entry[/\"(.*)\"/]
    status_re = log_entry[/\"\s+\d+\s+/]
    
    if status_re != nil
      status_re.gsub!(" ","")
      status_re.gsub!("\"","")
    end
    
    name_re = log_entry[/(\w*)[-]*\s+\[/]

    if name_re != nil
      name_re.gsub!(" ","")
      name_re.gsub!("\[","")
    end
    
    # Check for valid ip address
    if (ip_re == nil) | ((ip_re =~ /^(\b([0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])\b).(\b([0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])\b).(\b([0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])\b).(\b([0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])\b)$/) == nil)
      puts "no"
      exit
    end
    
    # Check bytes sent
    if (bytes_re == nil) | ((bytes_re =~ /^[0-9]+|-$/) == nil)
      puts "no"
      exit
    end
    
    # Check status of request
    if (status_re == nil) | ((status_re =~ /^[0-9]+$/) == nil)
      puts "no"
      exit
    end
    
    # Check if hyphen is present
    if (hyphen_re == nil) | ((hyphen_re =~ /-/) == nil)
      puts "no"
      exit
    end
    
    # Check name
    if (name_re == nil) | ((name_re =~ /^(\w+|-)$/) == nil)
      puts "no"
      exit
    end
    
    # Check date of page request
    if (date_re == nil) | ((date_re =~ /^\[\b([0-9]|1[0-9]|2[0-9]|3(0|1))\b\/(Jan|Feb|Mar|Apr|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\/([0-9]{4}):\b(0[0-9]|1[0-9]|2[0-3])\b:\b(0[0-9]|[1-4][0-9]|5[0-9])\b:\b(0[0-9]|[1-4][0-9]|5[0-9])\b -0400\]$/) == nil)
      puts "no"
      exit
    end
    
    # Check the actual request
    if (request_re != nil)
      if request_re.count("\"") == 2
        if (request_re =~ /^"GET \/\S+ HTTP\/1.(0|1)"$/) == nil
          puts "no"
          exit
        end
      else
        if (request_re.count("\"") - 2) != request_re.scan(/\\"/).length
          puts "no"
          exit
        end
      end
    end

  end # finished reading log file
  
  # At this point, all entries are valid :D
  puts "yes"
  exit
end

# Bytes mode

if mode == "bytes" then

  total_bytes = 0
  type_count = 1
  
  # Calculate the total amount of bytes sent across all entries
  IO.foreach(file) do |log_entry|
    
    bytes_re = log_entry[/(\d+|-)$/]
    
    if bytes_re != "-"
      total_bytes = total_bytes + (bytes_re.to_i)
    end
  end

  tmp_total_bytes = total_bytes
  
  if tmp_total_bytes < 1024
    puts "#{tmp_total_bytes.to_s} bytes"
    exit
  end

  # Determine if size should be represented as KB, MB, or GB
  while ((tmp_total_bytes /= 1024) >= 1024) & (type_count <= 3)
    type_count += 1
  end

  if type_count == 1
    puts "#{(total_bytes/1024).to_s} KB"
  elsif type_count == 2
    puts "#{(total_bytes/(1024*1024)).to_s} MB"
  else
    puts "#{(total_bytes/(1024*1024*1024)).to_s} GB"
  end
  
end

# Time mode

if mode == "time" then
  
  time_hash = Hash.new(0)

  # Create a hash with hours 00-23 and default values of 0
  (0..23).each do |k|
    if k < 10
      time_hash["0#{k}"] = 0
    else
      time_hash["#{k}"] = 0
    end

  end

  # Store values in hash for each hour a page was visited
  IO.foreach(file) do |log_entry|

    hour_re = log_entry[/:\b(0[0-9]|1[0-9]|2[0-3])\b:/]
    hour_re.gsub!(":","")

    # If hour is already in the hash, incriment the value
    time_hash.keys.each do |key|
      if key == hour_re
        time_hash["#{key}"] +=1
      end
    end

  end
  
  # Sort the hash based on hour
  sorted_time_hash = time_hash.sort
  
  # Print the Array 
  sorted_time_hash.each do |key, value|
    puts "#{key} #{value}"
  end
  exit
end

# Popularity mode

if mode == "popularity" then
  
  request_hash = Hash.new(0)
  
  IO.foreach(file) do |log_entry|
    
    request_re = log_entry[/\"(.*)\"/]
    
    # If hash does not contain the request, create an entry
    if request_hash.has_key?("#{request_re}") == nil
      request_hash["#{request_re}"] = 0
    else
    # If hash contains request, incriment
      request_hash["#{request_re}"] += 1
    end
  end
  
  # Get the number of key-value pairs and then sort in decending order
  hash_elements = request_hash.size
  sorted_request_hash = request_hash.sort_by {|key, value| -value}
  
  # More than 10 elements, print the first 10
  if hash_elements > 10
    count = 0
    sorted_request_hash.each do |key, value|
      if count >= 10
        break
      end
      count += 1
      puts "#{value} #{key}"
    end
    # Fewer than 10 or exactly 10 elements, just print the array
  else
    sorted_request_hash.each do |key, value|
      puts "#{value} #{key}"
    end
  end
  exit
end




