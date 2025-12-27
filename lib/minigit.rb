require_relative "commands"

if ARGV.empty?
  puts "Welcome to minigit"
  puts "#### help #### "
  puts "- init:initializes a minigit repo"
end

command = ARGV[0]


case command
when "init"
  Commands.init_command
when "add"
  # a file parameter must be added to the command. This only working with one file
  args = ARGV[1..]
  Commands.add_command(args)
when "commit"
  commit_message = ARGV[1]
  Commands.commit_command(commit_message)
when "log"
  Commands.log_command
when "status"
  Commands.status_command
end