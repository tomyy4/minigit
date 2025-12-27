require_relative "file_service"
require "time"
require "fileutils"


module Commands
  def self.init_command
    if FileService.minigit_exists
      puts "Repo already initialized"
      return
    end
    
    # move this to file service
    Dir.mkdir ".minigit"
    Dir.mkdir ".minigit/objects"
    FileUtils.touch ".minigit/index"
    FileUtils.touch ".minigit/HEAD"
    puts ".minidigit directory created"
  end
  
  def self.add_command(args)
    if not FileService.minigit_exists
      puts ".minigit not initialized"
      return
    end
  
    if args.empty?
      puts "Nothing specified"
      return 
    end
  
    for filename in args
      unless File.file?(filename)
        puts "Fatal: file #{filename} does not exist"
        return
      else
        FileService.stage_file(filename)
      end
    end
  end

  def self.commit_command(message)
    # We will have the folloing strucutre
    #.minigit/
    #└── objects/
    #  └── <commit_id>/
    #      ├── meta
    #      └── files/
    #          ├── file1.txt
    #          ├── file2.rb
    #          └── ...    
    ##### SNAPSHOT #####
    # Meta file must follow
    # commit: <commit_id>
    # parent: <parent_commit_id | none>
    # date: <ISO timestamp>
    # message: <mensaje>
    if not FileService.minigit_exists
      puts "minigit not initialized"
      return
    end

    if FileService.index_file_is_empty?
      puts "No files staged to be commited"
      return
    end

    if not message
      puts "You must provide a message"
      return
    end

    if message.to_s.strip.empty?
      puts "Commit message cannot be empty"
      return
    end

    # generate md5 from iso time, index content, commit message and parent commit if provided
    md5 = Digest::MD5.new
    current_time = Time.now.iso8601
    strings = [message, current_time, FileService.index_file_content]

    strings.each do |str|
      md5.update(str)
    end 
    
    hex = md5.hexdigest
    FileService.generate_commit(hex, current_time, message)
    puts "executing commit"
  end

  def self.log_command(parent_commit = nil)    
    if not parent_commit
      commit = FileService.get_parent_commit
    else
      commit = parent_commit
    end

    return puts "No commits yet" unless commit

    # look for the directory with the last commit
    parent_commit = nil
    meta_file = ".minigit/objects/#{commit}/meta"

    meta = FileService.read_meta(meta_file)
    puts "commit #{meta[:commit]}"
    puts "parent #{meta[:parent]}"
    puts "message #{meta[:message]}"
    puts "date #{meta[:date]}"
    puts "-------"

    parent_commit = meta[:parent]
    
    if not parent_commit
      return
    end

    self.log_command(parent_commit)
  end

  def self.status_command
    last_commit = FileService.get_parent_commit

    staged_files = FileService.get_staged_files
    puts "Staged files:"
    staged_files.each do |f|
      puts "- #{f}"
    end
    puts
    last_commit = FileService.get_parent_commit
    puts "Modified but not staged:"
    FileService.get_modified_but_not_staged_files(last_commit).each do |f|
      puts "- #{f}"
    end
    puts 
    puts "Untracked files:"
    untracked_files = FileService.get_untracked_files(last_commit)
    untracked_files.each do |f|
      puts "- #{f}"
    end
  end
end
