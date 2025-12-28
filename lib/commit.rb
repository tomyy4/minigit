require_relative "head"
require_relative "index"

module Commit
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

  # consider a better name for this def
  def self.add_commited_files(commit_file_path)
    Index.get_files.each do |file|
      FileUtils.cp(file, commit_file_path)
    end
  end

  def self.create(hex, current_time, commit_message)
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
    parent_commit = Head.get_parent_commit

    if not parent_commit
      parent_commit = "none"
    end

    self.add_commited_files(committed_files_path)
    self.generate_meta_file(commit_dir_path, hex, current_time, commit_message, parent_commit)
    Index.clear
    Head.update(hex)
  end
end