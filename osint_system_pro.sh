#!/bin/bash

USER_FILE="users.txt"
LOGFILE="osint_log.txt"
BANNED="banned.txt"
HISTORY="osint_history.txt"

# =========================
# 📜 LOG SYSTEM
# =========================
log() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') | USER:$user | $1" >> "$LOGFILE"
}

# =========================
# 🚫 BAN CLEANUP (AUTO UNBAN)
# =========================
cleanup_bans() {
  now=$(date +%s)
  tmp="banned_tmp.txt"
  > "$tmp"

  while IFS=":" read u t d r; do
    [ -z "$u" ] && continue

    end=$((t + d))

    # si pas expiré -> on garde
    if [ "$now" -lt "$end" ]; then
      echo "$u:$t:$d:$r" >> "$tmp"
    fi
  done < "$BANNED"

  mv "$tmp" "$BANNED"
}

# =========================
# 🚫 CHECK BAN
# =========================
is_banned() {
  now=$(date +%s)
  user_clean=$(echo "$user" | tr -d '\r' | xargs)

  while IFS=":" read u t d r; do
    [ -z "$u" ] && continue

    if [ "$u" = "$user_clean" ]; then
      end=$((t + d))
      if [ "$now" -lt "$end" ]; then
        return 0
      fi
    fi
  done < "$BANNED"

  return 1
}

# clean bans at start
cleanup_bans

# =========================
# 🔐 LOGIN
# =========================
clear
echo "🔐 OSINT SYSTEM PRO"

TRIES=0
MAX_TRIES=3
LOGIN_OK=false
ROLE=0

while [ $TRIES -lt $MAX_TRIES ]; do
  read -p "Username: " user
  read -s -p "Password: " pass
  echo ""

  user=$(echo "$user" | tr -d '\r' | xargs)

  if is_banned; then
    echo "🚫 ACCOUNT TEMP BANNED"
    exit
  fi

  while IFS=":" read u p r; do
    if [ "$user" = "$u" ] && [ "$pass" = "$p" ]; then
      ROLE=$r
      LOGIN_OK=true
      echo "✅ ACCESS GRANTED"
      log "LOGIN SUCCESS"
      break
    fi
  done < "$USER_FILE"

  if [ "$LOGIN_OK" = true ]; then
    break
  fi

  TRIES=$((TRIES+1))
  echo "❌ WRONG ($TRIES/$MAX_TRIES)"
  log "FAILED LOGIN"

  if [ $TRIES -eq $MAX_TRIES ]; then
    echo "🚫 SYSTEM LOCKED"
    log "KICKED"
    exit
  fi
done

# =========================
# 🌈 HEADER
# =========================
header() {
  clear
  echo "====================================="
  echo -e "\e[1;35m     OSINT SYSTEM PRO\e[0m"
  echo "====================================="
}

# =========================
# 🚀 BOOT
# =========================
clear
echo "BOOTING..."

for i in {1..20}; do
  printf "\r["
  for ((j=0;j<i;j++)); do printf "#"; done
  for ((j=i;j<20;j++)); do printf "."; done
  printf "] %s%%" $((i*5))
  sleep 0.02
done

echo ""
echo "READY"
sleep 0.5

read -p "ENTER..."

# =========================
# 🧠 MENU
# =========================
while true; do
  header
  echo ""

  echo "1) 🔍 IP Lookup"
  echo "2) 🌍 My IP"

  if [ "$ROLE" -ge 1 ]; then
    echo "3) 📡 Network Scan"
  fi

  if [ "$ROLE" -ge 2 ]; then
    echo "4) 📜 Logs"
  fi

  if [ "$ROLE" -ge 3 ]; then
    echo "5) 👑 Create User"
    echo "6) 🚫 Ban User"
    echo "7) 🔓 Unban User"
  fi

  echo "0) 🚪 Exit"
  echo ""

  read -p "Choice: " c

  # EXIT
  [ "$c" = "0" ] && log "EXIT" && exit

  # IP LOOKUP
  if [ "$c" = "1" ]; then
    read -p "Target IP: " IP
    DATA=$(curl -s ipinfo.io/$IP)

    echo "$DATA" | grep -q .

    echo ""
    echo "IP INFO:"
    echo "$DATA"

    log "IP LOOKUP $IP"
    echo "$IP | lookup" >> "$HISTORY"
    read -p "ENTER..."
  fi

  # MY IP
  if [ "$c" = "2" ]; then
    IP=$(curl -s ifconfig.me)
    echo "YOUR IP: $IP"
    log "MY IP"
    read -p "ENTER..."
  fi

  # NETWORK SCAN
  if [ "$c" = "3" ] && [ "$ROLE" -ge 1 ]; then
    NET=$(ip route | grep -oE '([0-9]{1,3}\.){3}0/24' | head -1)
    [ -z "$NET" ] && NET="192.168.1.0/24"

    echo "Scanning $NET"
    log "SCAN"
    nmap -sn "$NET"
    read -p "ENTER..."
  fi

  # LOGS
  if [ "$c" = "4" ] && [ "$ROLE" -ge 2 ]; then
    cat "$LOGFILE"
    read -p "ENTER..."
  fi

  # CREATE USER
  if [ "$c" = "5" ] && [ "$ROLE" -ge 3 ]; then
    read -p "User: " nu
    read -s -p "Pass: " np
    echo ""
    read -p "Role (1/2/3): " nr

    echo "$nu:$np:$nr" >> "$USER_FILE"
    log "USER CREATED $nu"
    echo "OK"
    read -p "ENTER..."
  fi

  # BAN USER (TEMP)
  if [ "$c" = "6" ] && [ "$ROLE" -ge 3 ]; then
    read -p "User to ban: " ban
    read -p "Duration (sec): " dur
    read -p "Reason: " reason

    time=$(date +%s)

    echo "$ban:$time:$dur:$reason" >> "$BANNED"

    log "BAN $ban $dur sec $reason"
    echo "🚫 BANNED"
    read -p "ENTER..."
  fi

  # UNBAN USER (FORCE REMOVE)
  if [ "$c" = "7" ] && [ "$ROLE" -ge 3 ]; then
    read -p "User to unban: " unban

    grep -Fv "^$unban:" "$BANNED" > tmp && mv tmp "$BANNED"

    log "UNBAN $unban"
    echo "🔓 UNBANNED"
    read -p "ENTER..."
  fi

done
