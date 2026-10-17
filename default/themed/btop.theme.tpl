# Main background, empty for terminal default, need to be empty if you want transparent background
theme[main_bg]="{{ background }}"

# Main text color
theme[main_fg]="{{ foreground }}"

# Title color for boxes
theme[title]="{{ foreground }}"

# Highlight color for keyboard shortcuts
theme[hi_fg]="{{ accent }}"

# Background color of selected item in processes box
theme[selected_bg]="{{ selection }}"

# Foreground color of selected item in processes box
theme[selected_fg]="{{ selection_foreground }}"

# Color of inactive/disabled text
theme[inactive_fg]="{{ comment }}"

# Color of text appearing on top of graphs, i.e uptime and current network graph scaling
theme[graph_text]="{{ light_foreground }}"

# Background color of the percentage meters
theme[meter_bg]="{{ lighter_background }}"

# Misc colors for processes box including mini cpu graphs, details memory graph and details status text
theme[proc_misc]="{{ light_foreground }}"

# CPU, Memory, Network, Proc box outline colors
theme[cpu_box]="{{ border }}"
theme[mem_box]="{{ border }}"
theme[net_box]="{{ border }}"
theme[proc_box]="{{ border_focus }}"

# Box divider line and small boxes line color
theme[div_line]="{{ border }}"

# Temperature graph color, neutral when cool, warning in orange and critical in red
theme[temp_start]="{{ comment }}"
theme[temp_mid]="{{ orange }}"
theme[temp_end]="{{ red }}"

# CPU graph colors
theme[cpu_start]="{{ mix border_focus accent 20% }}"
theme[cpu_mid]="{{ accent }}"
theme[cpu_end]="{{ mix accent foreground 50% }}"

# Mem/Disk free meter
theme[free_start]="{{ comment }}"
theme[free_mid]="{{ light_foreground }}"
theme[free_end]="{{ foreground }}"

# Mem/Disk cached meter
theme[cached_start]="{{ comment }}"
theme[cached_mid]="{{ light_foreground }}"
theme[cached_end]="{{ foreground }}"

# Mem/Disk available meter
theme[available_start]="{{ comment }}"
theme[available_mid]="{{ light_foreground }}"
theme[available_end]="{{ foreground }}"

# Mem/Disk used meter
theme[used_start]="{{ mix border_focus accent 20% }}"
theme[used_mid]="{{ accent }}"
theme[used_end]="{{ mix accent foreground 50% }}"

# Download graph colors
theme[download_start]="{{ mix border_focus accent 20% }}"
theme[download_mid]="{{ accent }}"
theme[download_end]="{{ mix accent foreground 50% }}"

# Upload graph colors
theme[upload_start]="{{ comment }}"
theme[upload_mid]="{{ light_foreground }}"
theme[upload_end]="{{ foreground }}"

# Process box color gradient for threads, mem and cpu usage
theme[process_start]="{{ mix border_focus accent 20% }}"
theme[process_mid]="{{ accent }}"
theme[process_end]="{{ mix accent foreground 50% }}"

# Process list banner while paused, following, or both
theme[proc_pause_bg]="{{ mix background orange 30% }}"
theme[proc_follow_bg]="{{ mix background accent 30% }}"
theme[proc_banner_bg]="{{ mix background red 30% }}"
theme[proc_banner_fg]="{{ foreground }}"

# Followed process row
theme[followed_bg]="{{ mix background accent 30% }}"
theme[followed_fg]="{{ foreground }}"
