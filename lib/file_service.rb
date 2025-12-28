require_relative "md5_generator"
require_relative "index"
require_relative "head"
require_relative "commit"

module FileService
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
end