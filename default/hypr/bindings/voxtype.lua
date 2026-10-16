if o.cmd_present("voxtype") then
  o.bind("SUPER + CTRL + X", "Toggle dictation", "voxtype record toggle")
  o.bind_hold("F9", "Start dictation (push-to-talk)", "voxtype record start", "Stop dictation (push-to-talk)", "voxtype record stop")
end
