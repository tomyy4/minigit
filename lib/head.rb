module Head

  def self.update(hex)
    File.open(".minigit/HEAD", "w") do |f|
      f.write(hex)
    end
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
end