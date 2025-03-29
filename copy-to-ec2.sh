#!/bin/bash

# Script to copy a directory or file to an EC2 instance

# Usage: ./copy-to-ec2.sh -k /path/to/your/private/key.pem -s /path/to/source -d username@your-ec2-instance-public-ip:/path/to/destination

# Options:
#   -k: Path to your private key file (.pem) (required)
#   -s: Path to the source file or directory (required)
#   -d: Destination on the EC2 instance (username@ip:path) (required)

# Example usage:
# ./copy-to-ec2.sh -k ~/.ssh/my-ec2-key.pem -s /home/user/myproject -d ec2-user@54.123.45.67:/home/ec2-user/
# ./copy-to-ec2.sh -k ~/.ssh/my-ec2-key.pem -s /home/user/myfile.txt -d ec2-user@54.123.45.67:/home/ec2-user/

# Parse command-line arguments
while getopts "k:s:d:" opt; do
  case $opt in
    k) KEY="$OPTARG" ;;
    s) SOURCE="$OPTARG" ;;
    d) DESTINATION="$OPTARG" ;;
    \?) echo "Invalid option -$OPTARG" >&2; exit 1 ;;
  esac
done

# Check if required arguments are provided
if [[ -z "$KEY" || -z "$SOURCE" || -z "$DESTINATION" ]]; then
  echo "Usage: $0 -k /path/to/your/private/key.pem -s /path/to/source -d username@your-ec2-instance-public-ip:/path/to/destination"
  exit 1
fi

# Check if the key file exists
if [[ ! -f "$KEY" ]]; then
  echo "Error: Private key file not found at $KEY"
  exit 1
fi

# Check if the source exists
if [[ ! -e "$SOURCE" ]]; then
  echo "Error: Source file or directory not found at $SOURCE"
  exit 1
fi

# Check if the destination is properly formatted.
if [[ ! "$DESTINATION" =~ ^.*@.*:.*$ ]]; then
    echo "Error: Destination must be in the format username@ip:path"
    exit 1
fi

# Determine if the source is a file or directory
if [[ -d "$SOURCE" ]]; then
  # Copy directory recursively
  scp -i "$KEY" -r "$SOURCE" "$DESTINATION"
else
  # Copy single file
  scp -i "$KEY" "$SOURCE" "$DESTINATION"
fi

# Check the exit status of scp
if [[ $? -eq 0 ]]; then
  echo "Copy successful!"
else
  echo "Copy failed."
  exit 1
fi

exit 0
