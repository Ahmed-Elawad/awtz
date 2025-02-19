# awtz

A collection of handy scripts I used more than once.

## Badges
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

---

## Table of Contents

- [Overview](#overview)
- [Connect-to-EC2 Utility](#connect-to-ec2-utility)
  - [Features](#features)
  - [Usage Examples](#usage-examples)
  - [Interactive Menu](#interactive-menu)
- [Repo Butler Utility](#repo-butler-utility)
  - [Features](#features-1)
  - [Usage Examples](#usage-examples-1)

---

## Connect-to-EC2 Utility

The `connect-to-ec2` script is a helper tool for managing SSH connections to EC2 instances. It allows you to:

- **Connect directly** to an EC2 instance using flags for IP and SSH key.
- **Interactively choose** between connecting to a new instance or one of your previously saved instances.
- **Save instance details** (name, IP, and SSH key) for quick future access.
- **Clean up saved instances** by removing entries that are no longer needed.

### Features

<details>
  <summary><strong>Click to expand feature details</strong></summary>

- **Command-Line Flags:**
  - `-i`: Specify the EC2 instance IP address.
  - `-k`: Specify the SSH key path (e.g., `~/.ssh/my-key.pem`).
  - `-n`: Optionally assign a name to the instance.
  - `-h`: Display the help message.

- **Interactive Menu:**
  - **Connect to an existing saved instance:** Lists all saved instances with their names, IP addresses, and key information.
  - **Connect to a new instance:** Prompts you for details and gives you the option to save the instance for future use.
  - **Clean up saved instances:** Allows you to remove outdated or unwanted saved instance entries.

- **Ease of Use:**  
  The script constructs the SSH connection string automatically (defaulting to user `ubuntu`) and handles key selection with a user-friendly menu.

</details>

### Usage Examples

Run the script with command-line flags:

```bash
# Connect directly to an instance and optionally save it:
connect-to-ec2 -i 1.2.3.4 -k ~/.ssh/my-key.pem -n "MyInstance"
```

## Repo Butler Utility

The `repo-butler.sh` script is a helper tool for removing the .github/workflows
directory on remote branches featuring "WI-0" in their name. It allows you to:

- **Clean up branches** by removing workflow files.
- **Automatically commit and push** changes with convenient flags.
- **Use GPG signing** for commits.

### Features

<details>
  <summary><strong>Click to expand feature details</strong></summary>

- **Command-Line Flags:**
  - `-A`: Automatically commit the removal without prompting.
  - `-P`: Automatically push the changes after a commit without prompting.
  - `-v`: Enable verbose logging.
  - `-S`: Sign commits using your configured GPG key.
  - `-h`: Display the help message.

- **Automated Cleanup:**
  - Locates branches containing "WI-0" in their name.
  - Removes the .github/workflows folder if present, prompting or auto-committing/pushing.

- **Ease of Use:**  
  The script fetches all remote branches, checks them out locally, then handles commit and push behavior as instructed.

</details>

### Usage Examples

Run the script with relevant flags:

```bash
# Automatically commit removal of .github/workflows and push the result:
./repo-butler.sh -A -P


