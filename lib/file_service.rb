require_relative "md5_generator"
require_relative "index"


module FileService
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
    staged_files = Index.get_files
 
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

    staged_files = Index.get_files
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

  def self.add_commited_files(commit_file_path)
    Index.get_files.each do |file|
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
    Index.clear
    self.update_head_file(hex)
  end
end