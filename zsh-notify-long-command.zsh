_notify () {
  echo $'\e]9;'"${@:-Command completed}"'\007'
}

if [[ -z $NOTIFY_EXCLUDE ]]; then
  typeset -a NOTIFY_EXCLUDE=(
      caffeinate
      lazygit
      lg
      screen
      ssh
      vi
      vim
      watch
      watchexec
  )
fi
if [[ -z $NOTIFY_MIN_SECONDS ]]; then
  local NOTIFY_MIN_SECONDS=10
fi

function notify_preexec() {
  # executed between when you press enter on a command prompt 
  # but before command is executed
  NOTIFY_CMD="$1"

  if [[ ${NOTIFY_CMD:0:1} == " " ]]; then
    # line starts with a space so don't send a notification
    return
  fi

  if [ -n "$NOTIFY_EXCLUDE" ]; then
    for exc in $NOTIFY_EXCLUDE; do
      if [[ "$NOTIFY_CMD" == *"$exc"* ]]; then
        # this command is excluded
        return
      fi
    done
  fi
  NOTIFY_TIMER=${NOTIFY_TIMER:-$SECONDS}
}


function notify_precmd() {
  # executed before prompt is displayed 
  if [ $NOTIFY_TIMER ]; then
    NOTIFY_DURATION=$(($SECONDS - $NOTIFY_TIMER))
    if [[ $NOTIFY_DURATION -gt $NOTIFY_MIN_SECONDS ]]; then
      local hours=$(($NOTIFY_DURATION / 3600))
      local minutes=$((($NOTIFY_DURATION % 3600) / 60))
      local seconds=$(($NOTIFY_DURATION % 60))
      local display_duration=$(printf "%02d:%02d:%02d" hours minutes seconds)
      local notify_payload="command \"${NOTIFY_CMD}\" on $(hostname) complete (took ${display_duration})"
      _notify "$notify_payload"
    fi
    unset NOTIFY_TIMER
    unset NOTIFY_CMD
  fi
}

precmd_functions=("${(@)precmd_functions:#notify_precmd}")
precmd_functions+=(notify_precmd)
preexec_functions=("${(@)preexec_functions:#notify_preexec}")
preexec_functions+=(notify_preexec)
