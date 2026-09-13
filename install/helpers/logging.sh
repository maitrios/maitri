maitri_log_to_stdout() {
  [[ ${MAITRI_LOG_TO_STDOUT:-} == "1" || -z ${MAITRI_INSTALL_LOG_FILE:-} ]]
}

maitri_log_line() {
  if maitri_log_to_stdout; then
    echo "$1"
  else
    echo "$1" >>"$MAITRI_INSTALL_LOG_FILE"
  fi
}

start_install_log() {
  if ! maitri_log_to_stdout; then
    mkdir -p "$(dirname "$MAITRI_INSTALL_LOG_FILE")"
    touch "$MAITRI_INSTALL_LOG_FILE"
    chmod 666 "$MAITRI_INSTALL_LOG_FILE" 2>/dev/null || true
  fi

  export MAITRI_START_TIME="${MAITRI_START_TIME:-$(date '+%Y-%m-%d %H:%M:%S')}"
  export MAITRI_START_EPOCH="${MAITRI_START_EPOCH:-$(date +%s)}"

  maitri_log_line "=== maitri Setup Started: $MAITRI_START_TIME ==="
}

stop_install_log() {
  local end_time end_epoch duration mins secs
  end_time=$(date '+%Y-%m-%d %H:%M:%S')
  end_epoch=$(date +%s)

  maitri_log_line "=== maitri Setup Completed: $end_time ==="

  if [[ -n ${MAITRI_START_EPOCH:-} ]]; then
    duration=$((end_epoch - MAITRI_START_EPOCH))
    mins=$((duration / 60))
    secs=$((duration % 60))
    maitri_log_line "maitri setup: ${mins}m ${secs}s"
  fi
}

run_logged() {
  local script="$1"
  local exit_code errexit_was_set=0

  maitri_log_line "[$(date '+%Y-%m-%d %H:%M:%S')] Starting: $script"

  case $- in
    *e*)
      errexit_was_set=1
      set +e
      ;;
  esac

  local runner=(bash -eE)
  if [[ ${MAITRI_INSTALL_DEBUG:-} == "1" ]]; then
    runner=(bash -x -eE)
  fi

  if maitri_log_to_stdout; then
    PS4='+ ${BASH_SOURCE[0]##*/}:${LINENO}:${FUNCNAME[0]:-main}: ' \
      "${runner[@]}" -c 'source "$1"' bash "$script" </dev/null 2>&1
  else
    PS4='+ ${BASH_SOURCE[0]##*/}:${LINENO}:${FUNCNAME[0]:-main}: ' \
      "${runner[@]}" -c 'source "$1"' bash "$script" </dev/null >>"$MAITRI_INSTALL_LOG_FILE" 2>&1
  fi

  exit_code=$?
  (( errexit_was_set )) && set -e

  if (( exit_code == 0 )); then
    maitri_log_line "[$(date '+%Y-%m-%d %H:%M:%S')] Completed: $script"
  else
    maitri_log_line "[$(date '+%Y-%m-%d %H:%M:%S')] Failed: $script (exit code: $exit_code)"
  fi

  return $exit_code
}
