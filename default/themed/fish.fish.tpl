set -U fish_color_normal {{ foreground_strip }}
set -U fish_color_command {{ green_strip }}
set -U fish_color_builtin {{ cyan_strip }}
set -U fish_color_keyword {{ magenta_strip }}
set -U fish_color_quote {{ yellow_strip }}
set -U fish_color_redirection {{ magenta_strip }}
set -U fish_color_end {{ magenta_strip }}
set -U fish_color_operator {{ magenta_strip }}
set -U fish_color_escape {{ magenta_strip }}
set -U fish_color_param {{ foreground_strip }}
set -U fish_color_option {{ orange_strip }}
set -U fish_color_valid_path --underline
set -U fish_color_error {{ red_strip }}
set -U fish_color_comment {{ comment_strip }} --italics
set -U fish_color_autosuggestion {{ comment_strip }}
set -U fish_color_selection {{ foreground_strip }} --background={{ selection_strip }}
set -U fish_color_search_match {{ foreground_strip }} --background={{ selection_strip }} --bold
set -U fish_color_match --background={{ selection_strip }}
set -U fish_color_history_current {{ accent_strip }} --bold
set -U fish_color_cancel {{ comment_strip }}
set -U fish_color_cwd {{ accent_strip }}
set -U fish_color_cwd_root {{ red_strip }}
set -U fish_color_user {{ green_strip }}
set -U fish_color_host {{ foreground_strip }}
set -U fish_color_host_remote {{ yellow_strip }}
set -U fish_color_status {{ red_strip }}
set -U fish_pager_color_progress {{ background_strip }} --background={{ accent_strip }}
set -U fish_pager_color_prefix {{ accent_strip }} --bold
set -U fish_pager_color_completion {{ foreground_strip }}
set -U fish_pager_color_description {{ comment_strip }}
set -U fish_pager_color_selected_background --background={{ selection_strip }}
set -U fish_pager_color_selected_prefix {{ foreground_strip }} --bold --underline
set -U fish_pager_color_selected_completion {{ foreground_strip }}
set -U fish_pager_color_selected_description {{ light_foreground_strip }}
