#!/bin/bash
# connect-to-ec2
# A helper script to connect to EC2 instances via SSH,
# save instance details, and clean up saved entries.
#
# Usage examples:
#   connect-to-ec2 -i 1.2.3.4 -k ~/.ssh/my-key.pem -n "MyInstance"
#   connect-to-ec2
#

CONFIG_FILE="$HOME/.ec2_instances"

function show_help() {
  cat <<EOF
Usage: connect-to-ec2 [options]

Options:
  -i IP_ADDRESS   Specify the EC2 instance IP address
  -k KEY_PATH     Specify the SSH key path (e.g., ~/.ssh/my-key.pem)
  -n NAME         Specify a name for the instance (optional)
  -h              Show this help message

Without options, an interactive menu is presented.
EOF
}

function connect_instance() {
  local ip=$1
  local key=$2
  local user="ubuntu"
  echo "Connecting to EC2 instance at $ip using key $key..."
  ssh -i "$key" ${user}@${ip}
}

function list_saved_instances() {
  if [ ! -f "$CONFIG_FILE" ] || [ ! -s "$CONFIG_FILE" ]; then
    echo "No saved instances found."
    return 1
  fi

  echo "Saved Instances:"
  local count=1
  while IFS="|" read -r name ip key; do
    printf "%d) %s - %s (Key: %s)\n" "$count" "${name:-N/A}" "$ip" "$key"
    count=$((count+1))
  done < "$CONFIG_FILE"
}

function select_saved_instance() {
  if [ ! -f "$CONFIG_FILE" ] || [ ! -s "$CONFIG_FILE" ]; then
    echo "No saved instances found."
    exit 1
  fi

  list_saved_instances
  echo -n "Select an instance number: "
  read selection
  local line
  line=$(sed -n "${selection}p" "$CONFIG_FILE")
  if [ -z "$line" ]; then
    echo "Invalid selection."
    exit 1
  fi
  local name ip key
  IFS="|" read -r name ip key <<< "$line"
  connect_instance "$ip" "$key"
}

function prompt_for_new_instance() {
  echo -n "Enter EC2 instance IP address: "
  read ip

  echo -n "Enter instance name (optional): "
  read name

  echo "Available SSH keys in ~/.ssh:"
  local keys=(~/.ssh/*)
  if [ ${#keys[@]} -eq 0 ]; then
    echo "No .pem files found in ~/.ssh. Please enter the full path to your SSH key: "
    read key
  else
    local count=1
    for k in "${keys[@]}"; do
      echo "$count) $k"
      count=$((count+1))
    done
    echo -n "Select a key number (or enter full path): "
    read key_choice
    if [[ "$key_choice" =~ ^[0-9]+$ ]] && [ "$key_choice" -ge 1 ] && [ "$key_choice" -le ${#keys[@]} ]; then
      key="${keys[$((key_choice-1))]}"
    else
      key="$key_choice"
    fi
  fi

  echo -n "Save this instance for future use? (y/n): "
  read save_choice
  if [[ "$save_choice" =~ ^[Yy]$ ]]; then
    echo "${name}|${ip}|${key}" >> "$CONFIG_FILE"
    echo "Instance saved."
  fi

  connect_instance "$ip" "$key"
}

function cleanup_saved_instances() {
  if [ ! -f "$CONFIG_FILE" ] || [ ! -s "$CONFIG_FILE" ]; then
    echo "No saved instances to clean up."
    return
  fi

  while true; do
    list_saved_instances
    echo -n "Enter the number of the instance to remove (or 0 to cancel): "
    read selection
    if [ "$selection" == "0" ]; then
      break
    fi
    local total_lines
    total_lines=$(wc -l < "$CONFIG_FILE")
    if [ "$selection" -gt "$total_lines" ] || [ "$selection" -lt 1 ]; then
      echo "Invalid selection."
    else
      sed -i "${selection}d" "$CONFIG_FILE"
      echo "Instance removed."
    fi
    echo -n "Remove another instance? (y/n): "
    read cont
    if [[ ! "$cont" =~ ^[Yy]$ ]]; then
      break
    fi
  done
}


if [ $# -gt 0 ]; then
  while getopts "i:k:n:h" opt; do
    case "$opt" in
      i) ip="$OPTARG" ;;
      k) key="$OPTARG" ;;
      n) name="$OPTARG" ;;
      h) show_help; exit 0 ;;
      *) show_help; exit 1 ;;
    esac
  done

  if [ -z "$ip" ] || [ -z "$key" ]; then
    echo "Error: Both IP address and key path are required."
    show_help
    exit 1
  fi

  if [ -n "$name" ]; then
    echo -n "Save this instance for future use? (y/n): "
    read save_choice
    if [[ "$save_choice" =~ ^[Yy]$ ]]; then
      echo "${name}|${ip}|${key}" >> "$CONFIG_FILE"
      echo "Instance saved."
    fi
  fi

  connect_instance "$ip" "$key"
else
  echo "EC2 Connection Menu:"
  echo "1) Connect to an existing saved instance"
  echo "2) Connect to a new instance"
  echo "3) Clean up saved instances"
  echo -n "Choose an option [1-3]: "
  read option
  case "$option" in
    1) select_saved_instance ;;
    2) prompt_for_new_instance ;;
    3) cleanup_saved_instances ;;
    *) echo "Invalid option." ; exit 1 ;;
  esac
fi

