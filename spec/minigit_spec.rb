require_relative "../lib/file_service"
require_relative "../lib/commands"
require "fileutils"

RSpec.describe "Minigit" do
  before(:each) do
    # Setup working tree
    Dir.mkdir(".minigit") unless Dir.exist?(".minigit")
    Dir.mkdir(".minigit/objects") unless Dir.exist?(".minigit/objects")
    FileUtils.touch(".minigit/index")
    FileUtils.touch(".minigit/HEAD")
    File.open("file1.txt", "w") { |f| f.write("Hello World") }
    File.open("file2.txt", "w") { |f| f.write("Another file") }
  end

  after(:each) do
    # Cleanup working tree
    FileUtils.rm_f("file1.txt")
    FileUtils.rm_f("file2.txt")
    FileUtils.rm_f(".minigit/index")
    FileUtils.rm_f(".minigit/HEAD")
    FileUtils.rm_rf(".minigit/objects")
    Dir.rmdir(".minigit") if Dir.exist?(".minigit")
  end

  describe "FileService" do
    it "detects that .minigit exists" do
      expect(FileService.minigit_exists).to eq(true)
    end

    it "stages a file" do
      FileService.stage_file("file1.txt")
      staged_files = FileService.get_staged_files
      expect(staged_files).to include("file1.txt")
    end

    it "returns modified but not staged files" do
      FileService.stage_file("file1.txt")
      # Commit file1.txt
      FileService.generate_commit("abc123", Time.now.iso8601, "First commit")
      # Modify file1.txt
      File.open("file1.txt", "w") { |f| f.write("Changed content") }
      modified = FileService.get_modified_but_not_staged_files("abc123")
      expect(modified).to include("file1.txt")
    end

    it "returns untracked files" do
      FileService.stage_file("file1.txt")
      FileService.generate_commit("abc123", Time.now.iso8601, "First commit")
      # file2.txt is untracked
      untracked = FileService.get_untracked_files("abc123")
      expect(untracked).to include("file2.txt")
    end
  end

  describe "Commands" do
    it "commits staged files" do
      FileService.stage_file("file1.txt")
      Commands.commit_command("Initial commit")
      last_commit = FileService.get_parent_commit
      expect(last_commit).not_to be_nil
      # Check files exist in commit folder
      commit_dir = ".minigit/objects/#{last_commit}/files"
      expect(Dir.children(commit_dir)).to include("file1.txt")
    end

    it "logs commits" do
      FileService.stage_file("file1.txt")
      Commands.commit_command("First commit")
      expect { Commands.log_command }.to output(/commit/).to_stdout
    end
  end
end
