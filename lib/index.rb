
module Index
  def self.is_empty?
    File.zero?(".minigit/index")
  end

  def self.clear
    File.open('.minigit/index', 'w') {|file| file.truncate(0) }
  end

  def self.content
    File.read(".minigit/index").to_s
  end

  def self.get_files
    path = ".minigit/index"
    lines = File.readlines(path)
  
    # does this generate a string?
    name_lines = lines.map do |line|
      name, _ = line.strip.split(":")
      name
      end

    name_lines
  end

  def self.find_staged_file_by_name(filename)
    # convert this to do end block
    file = File.open(".minigit/index", "r")
    file.each do |line|
      tracked_file = line.split(":")
      if tracked_file[0] == filename
        file.close
        return line
      end
    end
  
    file.close
  end

  def self.update_file_hash(filename, md5)  
    # updates a staged file that follows this structure
    # a_file.txt:any_hash  
    path = ".minigit/index"
    lines = File.readlines(path)
  
    # does this generate a string?
    updated_lines = lines.map do |line|
      name, _ = line.strip.split(":")
      if name == filename
        "#{name}:#{md5}\n"
      else
        line
      end
    end
  
    File.write(path, updated_lines.join)
  end


  def self.stage_file(filename)
    path = ".minigit/index"
    possible_staged_file = self.find_staged_file_by_name(filename)
    content = File.read(filename)
    md5 = Md5Generator.generate content.to_s
    if not possible_staged_file
      # Generate md5 hash and add to the staging area
      File.write(path, "#{filename}:#{md5}\n", mode: "a+")
    else
      # If the file is in the stage area, check the file has been updated vy checking its md5
      prev_md5 = possible_staged_file.split(":")[1].chomp

      if prev_md5.eql?(md5)
        puts "The file has no changes"
      else
        self.update_file_hash(filename, md5)
      end
    end
  end
end