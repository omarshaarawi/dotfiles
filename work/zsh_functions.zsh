backup() {
  if [[ $# -eq 2 ]]; then
    if [[ ! -d ~/OneDrive\ -\ Target\ Corporation/mac_backup/$2 ]]; then
      echo "Creating ~/OneDrive\ -\ Target\ Corporation/mac_backup/$2"
      mkdir ~/OneDrive\ -\ Target\ Corporation/mac_backup/$2
    fi
  fi
  cp -ai $1 ~/OneDrive\ -\ Target\ Corporation/mac_backup/$2
}


vpnl() {
  /opt/cisco/anyconnect/bin/vpn -s <<EOF
connect TGT_VPN_MAC
$USER
$PASSWORD
EOF
}

vpnd() {
  /opt/cisco/anyconnect/bin/vpn -s disconnect
}

gitfp(){
  git add . && git commit --amend --no-edit && git push -f && git status && git log
}

wait_do() {
    local watch_file=${1}
    shift

    if [[ ! -e ${watch_file} ]]; then
        echo "${watch_file} does not exist!"
        return 1
    fi

    if [[ `uname` == 'Linux' ]] && ! command -v inotifywait &>/dev/null; then
        echo "inotifywait not found!"
        return 1
    elif [[ `uname` == 'Darwin' ]] && ! command -v fswatch &>/dev/null; then
        echo "fswatch not found, install via 'brew install fswatch'"
        return 1
    fi

    local exclude_list="(\.cargo-lock|\.coverage$|\.git|\.hypothesis|\.mypy_cache|\.pgconf*|\.pyc$|__pycache__|\.pytest_cache|\.log$|^tags$|./target*|\.tox|\.yaml$)"
    if [[ `uname` == 'Linux' ]]; then
        while inotifywait -re close_write --excludei ${exclude_list} ${watch_file}; do
            local start=$(\date +%s)
            echo "start:    $(date)"
            echo "exec:     ${@}"
            ${@}
            local stop=$(\date +%s)
            echo "finished: $(date) ($((${stop} - ${start})) seconds elapsed)"
        done
    elif [[ `uname` == 'Darwin' ]]; then
        fswatch --one-per-batch --recursive --exclude ${exclude_list} --extended --insensitive ${watch_file} | (
            while read -r modified_path; do
                local start=$(\date +%s)
                echo "changed:  ${modified_path}"
                echo "start:    $(date)"
                echo "exec:     ${@}"
                ${@}
                local stop=$(\date +%s)
                echo "finished: $(date) ($((${stop} - ${start})) seconds elapsed)"
            done
        )
    fi
}
