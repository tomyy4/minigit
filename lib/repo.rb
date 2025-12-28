# module specialized on intializing the .minigit repo

require "fileutils"

module Repo
  def self.exists?
    File.directory?(".minigit")
  end

  def self.init
    Dir.mkdir ".minigit"
    Dir.mkdir ".minigit/objects"
    FileUtils.touch ".minigit/index"
    FileUtils.touch ".minigit/HEAD"
  end
end