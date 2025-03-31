-- Define our command table
commands = {
  help = "Display available commands",
  exit = "Exit the application",
  version = "Show application version",
  status = "Show server status"
}

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
  elseif commands[cmd] then
    return "Command '" .. cmd .. "' recognized but not implemented"
  else
    return "Unknown command: " .. cmd .. "\nType 'help' for available commands"
  end
end

print("Commands module loaded successfully")