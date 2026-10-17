[mgr]
cwd = { fg = "{{ accent }}", bold = true }
find_keyword = { fg = "{{ yellow }}", bold = true, italic = true, underline = true }
find_position = { fg = "{{ magenta }}", bg = "reset", bold = true, italic = true }
symlink_target = { fg = "{{ cyan }}", italic = true }
marker_copied = { fg = "{{ green }}", bg = "{{ green }}" }
marker_cut = { fg = "{{ red }}", bg = "{{ red }}" }
marker_marked = { fg = "{{ cyan }}", bg = "{{ cyan }}" }
marker_selected = { fg = "{{ yellow }}", bg = "{{ yellow }}" }
count_copied = { fg = "{{ background }}", bg = "{{ green }}" }
count_cut = { fg = "{{ background }}", bg = "{{ red }}" }
count_selected = { fg = "{{ background }}", bg = "{{ yellow }}" }
border_symbol = "│"
border_style = { fg = "{{ border }}" }

[tabs]
active = { fg = "{{ background }}", bg = "{{ accent }}", bold = true }
inactive = { fg = "{{ accent }}", bg = "{{ lighter_background }}" }

[mode]
normal_main = { fg = "{{ background }}", bg = "{{ accent }}", bold = true }
normal_alt = { fg = "{{ accent }}", bg = "{{ lighter_background }}" }
select_main = { fg = "{{ background }}", bg = "{{ red }}", bold = true }
select_alt = { fg = "{{ red }}", bg = "{{ lighter_background }}" }
unset_main = { fg = "{{ background }}", bg = "{{ red }}", bold = true }
unset_alt = { fg = "{{ red }}", bg = "{{ lighter_background }}" }

[indicator]
parent = { bg = "{{ lighter_background }}" }
current = { bg = "{{ lighter_background }}", bold = true }
preview = { underline = true }

[status]
perm_sep = { fg = "{{ comment }}" }
perm_type = { fg = "{{ green }}" }
perm_read = { fg = "{{ yellow }}" }
perm_write = { fg = "{{ red }}" }
perm_exec = { fg = "{{ cyan }}" }
progress_label = { fg = "{{ foreground }}", bold = true }
progress_normal = { fg = "{{ accent }}", bg = "{{ lighter_background }}" }
progress_error = { fg = "{{ red }}", bg = "{{ lighter_background }}" }

[which]
border = { fg = "{{ border_focus }}" }
mask = { bg = "{{ dark_background }}" }
cand = { fg = "{{ accent }}" }
rest = { fg = "{{ comment }}" }
desc = { fg = "{{ foreground }}" }
separator_style = { fg = "{{ comment }}" }

[confirm]
border = { fg = "{{ border_focus }}" }
title = { fg = "{{ accent }}", bold = true }
btn_yes = { fg = "{{ background }}", bg = "{{ accent }}", bold = true }
btn_no = { fg = "{{ foreground }}" }

[spot]
border = { fg = "{{ border_focus }}" }
title = { fg = "{{ accent }}", bold = true }
tbl_col = { fg = "{{ accent }}" }
tbl_cell = { bg = "{{ lighter_background }}", bold = true }

[notify]
title_info = { fg = "{{ green }}" }
title_warn = { fg = "{{ orange }}" }
title_error = { fg = "{{ red }}" }

[pick]
border = { fg = "{{ border_focus }}" }
active = { fg = "{{ accent }}", bold = true }

[input]
border = { fg = "{{ border_focus }}" }
title = { fg = "{{ accent }}" }
value = { fg = "{{ foreground }}" }
selected = { bg = "{{ selection }}" }

[cmp]
border = { fg = "{{ border_focus }}" }
active = { bg = "{{ lighter_background }}", bold = true }

[tasks]
border = { fg = "{{ border_focus }}" }
title = { fg = "{{ accent }}" }
hovered = { fg = "{{ accent }}", bold = true }

[help]
border = { fg = "{{ border_focus }}" }
chord = { fg = "{{ accent }}" }
action = { fg = "{{ foreground }}" }
hovered = { bg = "{{ lighter_background }}", bold = true }

[filetype]
rules = [
  { mime = "**/image/*", fg = "{{ yellow }}" },
  { mime = "**/{audio,video}/*", fg = "{{ magenta }}" },
  { mime = "**/application/{zip,rar,7z*,tar,gzip,xz,zstd,bzip*,lzma,compress,archive,cpio,arj,xar,ms-cab*}", fg = "{{ red }}" },
  { mime = "**/application/{pdf,doc,rtf}", fg = "{{ cyan }}" },
  { mime = "vfs/{absent,stale}", fg = "{{ comment }}" },
  { url = "*", is = "orphan", fg = "{{ background }}", bg = "{{ red }}" },
  { url = "*", is = "exec", fg = "{{ green }}" },
  { url = "*", is = "dummy", fg = "{{ background }}", bg = "{{ red }}" },
  { url = "*/", is = "dummy", fg = "{{ background }}", bg = "{{ red }}" },
  { url = "*/", fg = "{{ blue }}" },
]

[icon]
dirs = [
  { name = ".config", text = "", fg = "{{ orange }}" },
  { name = ".git", text = "", fg = "{{ cyan }}" },
  { name = ".github", text = "", fg = "{{ blue }}" },
  { name = ".npm", text = "", fg = "{{ blue }}" },
  { name = "Desktop", text = "", fg = "{{ cyan }}" },
  { name = "Development", text = "", fg = "{{ cyan }}" },
  { name = "Documents", text = "", fg = "{{ cyan }}" },
  { name = "Downloads", text = "", fg = "{{ cyan }}" },
  { name = "Library", text = "", fg = "{{ cyan }}" },
  { name = "Movies", text = "", fg = "{{ cyan }}" },
  { name = "Music", text = "", fg = "{{ cyan }}" },
  { name = "Pictures", text = "", fg = "{{ cyan }}" },
  { name = "Public", text = "", fg = "{{ cyan }}" },
  { name = "Videos", text = "", fg = "{{ cyan }}" },
]
conds = [
  { if = "orphan", text = "", fg = "{{ red }}" },
  { if = "link", text = "", fg = "{{ comment }}" },
  { if = "block", text = "", fg = "{{ yellow }}" },
  { if = "char", text = "", fg = "{{ yellow }}" },
  { if = "fifo", text = "", fg = "{{ yellow }}" },
  { if = "sock", text = "", fg = "{{ yellow }}" },
  { if = "sticky", text = "", fg = "{{ yellow }}" },
  { if = "dummy", text = "", fg = "{{ red }}" },
  { if = "dir & hovered", text = "", fg = "{{ blue }}" },
  { if = "dir", text = "", fg = "{{ blue }}" },
  { if = "exec", text = "", fg = "{{ green }}" },
  { if = "!dir", text = "", fg = "{{ foreground }}" },
]
