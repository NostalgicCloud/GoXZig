-- Define our command table
commands = {
  help = "Display available commands",
  exit = "Exit the application",
  version = "Show application version",
  status = "Show server status"
}
local mshould_exit = false

function list_commands()
  local result = "Available commands:\n"
  for cmd, desc in pairs(commands) do
    result = result .. "  " .. cmd .. " - " .. desc .. "\n"
  end
  return result
end

function handle_command(cmd)
  cmd = cmd:gsub("[\r\n]+$", "") -- Remove trailing newlines
  
  if cmd == "help" then
    return list_commands()
  elseif cmd == "version" then
    return "ZigxGo Version 0.0.0"
  elseif cmd == "status" then
    return "Server is running on port 8090"
  elseif cmd == "exit" then
    exit_application()
    return "Exiting application..."
  elseif commands[cmd] then
    return "Command '" .. cmd .. "' recognized but not implemented"
  else
    return "Unknown command: " .. cmd .. "\nType 'help' for available commands"
  end
end

function exit_application()
    mshould_exit = true
    print("mshould_exit set to: " .. tostring(mshould_exit))
end

function should_exit()
    print("should_exit called, returning: " .. tostring(mshould_exit))
    return mshould_exit
end

print("Commands module loaded successfully")