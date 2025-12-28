require_relative "md5_generator"

module FileService
  def self.minigit_exists
    File.directory?(".minigit")
  end

  def self.init_minigit
    Dir.mkdir ".minigit"
    Dir.mkdir ".minigit/objects"
    FileUtils.touch ".minigit/index"
    FileUtils.touch ".minigit/HEAD"
  end
  
  def self.index_file_is_empty?
    File.zero?(".minigit/index")
  end

  def self.index_file_content
    File.read(".minigit/index").to_s
  end

  def self.read_meta(meta_file)
    commit = nil
    parent = nil
    date = nil
    message = nil

    File.open(meta_file, "r") do |f|
      f.each do |line|
        name, value = line.strip.split(":", 2)
        if name == "commit"
          commit = value
        end

        if name == "date"
          date = value
        end

        if name == "message"
          message = value
        end

        if name == "parent"
          no_whitespace = value.gsub(/\s+/, "")
          if no_whitespace != "none"
            parent = no_whitespace
          else
            parent = nil
          end
        end
      end

      { commit:, parent:, date:, message: }
    end
  end

  def self.get_staged_files
    path = ".minigit/index"
    lines = File.readlines(path)
  
    # does this generate a string?
    name_lines = lines.map do |line|
      name, _ = line.strip.split(":")
      name
      end

    name_lines
  end

  def self.get_working_tree_files
    path = Dir.getwd
    files = []
    Dir.children(path).each do |f|
      if f != ".minigit"
        files << f
      end
    end
    files
  end

  def self.get_untracked_files(commit)
    commited_files = []
    last_commit_dir_path = ".minigit/objects/#{commit}/files"
    if File.directory?(last_commit_dir_path)
      commited_files = Dir.children(last_commit_dir_path)
    end

    working_tree_files = self.get_working_tree_files
    staged_files = self.get_staged_files
 
    files = []
    working_tree_files.each do |f|
      if !commited_files.include?(f) and !staged_files.include?(f)
        files << f
      end
    end
    files
  end

  def self.get_modified_but_not_staged_files(commit)
    return [] unless commit

    commit_files_path = ".minigit/objects/#{commit}/files"
    return [] unless File.directory?(commit_files_path)

    committed_hashes = {}
    Dir.children(commit_files_path).each do |file|
      content = File.read("#{commit_files_path}/#{file}")
      committed_hashes[file] = Md5Generator.generate(content)
    end

    staged_files = self.get_staged_files
    working_files = self.get_working_tree_files
  
    modified = []
  
    committed_hashes.each do |file, old_hash|
      next unless working_files.include?(file)      
      next if staged_files.include?(file)
  
      current_hash = Md5Generator.generate(File.read(file))
      modified << file if current_hash != old_hash
    end
  
    modified
  end

  def self.get_parent_commit
    # look inside head file, get the hash -> parent commit
    head_file = ".minigit/HEAD"
    if File.zero?(head_file)
      return nil 
    end

    hash = File.open(head_file) {|f| f.readline.chomp}
    hash
  end
  
  def self.generate_meta_file(
    commit_dir_path, 
    hex, 
    current_time, 
    commit_message,
    parent_commit
    )
    # Override HEAD file with every commit
    File.open("#{commit_dir_path}/meta", "w") do |f| 
      f.write("commit: #{hex}\n")
      f.write("parent: #{parent_commit}\n")
      f.write("date: #{current_time}\n")
      f.write("message: #{commit_message}")
    end
  end

  def self.update_head_file(hex)
    File.open(".minigit/HEAD", "w") do |f|
      f.write(hex)
    end
  end

  def self.clear_index_file
    # after a successful commit, clear the index file to avoid commiting the same
    # files everytime
    File.open('.minigit/index', 'w') {|file| file.truncate(0) }
  end

  def self.add_commited_files(commit_file_path)
    self.get_staged_files.each do |file|
      FileUtils.cp(file, commit_file_path)
    end
  end

  def self.generate_commit(hex, current_time, commit_message)
    # generate a dir with the hex as name
    commit_dir_path = ".minigit/objects/#{hex}"

    # refactor: use directory.exists to abstract minigit_exists def
    if File.directory?(commit_dir_path)
      puts "Commit directory #{commit_dir_path} already exists"
      return
    end

    Dir.mkdir commit_dir_path

    # create files dir, where our commited files will be stored
    committed_files_path = "#{commit_dir_path}/files"
    Dir.mkdir committed_files_path

    # create the specific meta file
    FileUtils.touch "#{commit_dir_path}/meta"
    parent_commit = self.get_parent_commit

    if not parent_commit
      parent_commit = "none"
    end

    self.add_commited_files(committed_files_path)
    self.generate_meta_file(commit_dir_path, hex, current_time, commit_message, parent_commit)
    self.clear_index_file
    self.update_head_file(hex)
  end

  def self.find_staged_file_by_name(filename)
    # convert this to block with do statement, 
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
    possible_staged_file = find_staged_file_by_name(filename)
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
        update_file_hash(filename, md5)
      end
    end
  end
end