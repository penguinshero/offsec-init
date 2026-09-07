#!/usr/bin/env python3

import os
import re
import sys
import platform
import subprocess
import shutil
import urllib.request


def run(cmd, check=True, capture=False):
    print(f"\n[+] Running: {' '.join(cmd)}")
    try:
        return subprocess.run(cmd, check=check, capture_output=capture, text=True)
    except subprocess.CalledProcessError as e:
        print(f"[-] Command failed: {' '.join(cmd)}")
        if capture and e.stderr:
            print(f"    {e.stderr.strip()}")
        sys.exit(1)
    except FileNotFoundError:
        print(f"[-] Command not found: {cmd[0]}")
        sys.exit(1)


def command_exists(command):
    return shutil.which(command) is not None


def valid_email(email):
    return re.match(r"^[^@\s]+@[^@\s]+\.[^@\s]+$", email) is not None


def get_git_config(key):
    result = subprocess.run(
        ["git", "config", "--global", "--get", key],
        capture_output=True, text=True
    )
    return result.stdout.strip() if result.returncode == 0 else None


def install_gcm():
    """Auto-detect arch and install latest GCM .deb release."""
    arch_map = {"x86_64": "amd64", "aarch64": "arm64"}
    arch = arch_map.get(platform.machine())
    if not arch:
        print(f"[-] Unsupported architecture: {platform.machine()}")
        print("[!] Install GCM manually: https://github.com/git-ecosystem/git-credential-manager")
        sys.exit(1)

    print("\n[+] Fetching latest GCM release info...")
    api_url = "https://api.github.com/repos/git-ecosystem/git-credential-manager/releases/latest"
    try:
        with urllib.request.urlopen(api_url, timeout=15) as resp:
            import json
            data = json.loads(resp.read())
    except Exception as e:
        print(f"[-] Could not fetch release info: {e}")
        sys.exit(1)

    asset = next(
        (a for a in data["assets"] if arch in a["name"] and a["name"].endswith(".deb")),
        None
    )
    if not asset:
        print("[-] No matching .deb asset found for your architecture.")
        sys.exit(1)

    deb_path = f"/tmp/{asset['name']}"
    print(f"[+] Downloading {asset['name']}...")
    urllib.request.urlretrieve(asset["browser_download_url"], deb_path)

    run(["sudo", "dpkg", "-i", deb_path])
    run(["git-credential-manager", "configure"])
    os.remove(deb_path)


def ensure_keyring_running():
    result = subprocess.run(["pgrep", "-x", "gnome-keyring-d"], capture_output=True)
    if result.returncode != 0:
        print("\n[!] gnome-keyring-daemon is not running.")
        answer = input("    Start it now? [Y/n]: ").strip().lower()
        if answer in ("", "y", "yes"):
            run(["gnome-keyring-daemon", "--start", "--components=secrets", "--replace"], check=False)
        else:
            print("[!] Secret Service storage may fail without the keyring daemon.")


def main():
    print("=" * 60)
    print("       Git + GCM Automatic Setup for Kali Linux")
    print("=" * 60)

    if os.geteuid() == 0:
        print("\n[!] Do NOT run this script with sudo.")
        print("[!] Run it as your normal user.")
        sys.exit(1)

    if not command_exists("git"):
        print("\n[-] Git is not installed.")
        print("[!] Install it with: sudo apt install git")
        sys.exit(1)

    if not command_exists("git-credential-manager"):
        print("\n[-] Git Credential Manager was not found.")
        answer = input("    Install it automatically now? [Y/n]: ").strip().lower()
        if answer in ("", "y", "yes"):
            install_gcm()
        else:
            print("[!] Install GCM first, then run this script again.")
            sys.exit(1)

    print("\n[+] Git and Git Credential Manager detected.")

    # Idempotency: skip if already configured
    existing_user = get_git_config("user.name")
    existing_email = get_git_config("user.email")
    if existing_user and existing_email:
        print(f"\n[i] Git already configured as: {existing_user} <{existing_email}>")
        answer = input("    Reconfigure? [y/N]: ").strip().lower()
        reconfigure = answer in ("y", "yes")
    else:
        reconfigure = True

    if reconfigure:
        print("\n--- GitHub Information ---")
        username = input("GitHub username: ").strip()
        email = input("GitHub email: ").strip()

        if not username or not re.match(r"^[A-Za-z0-9](?:[A-Za-z0-9-]*[A-Za-z0-9])?$", username):
            print("[-] Invalid GitHub username.")
            sys.exit(1)

        if not valid_email(email):
            print("[-] Invalid email format.")
            sys.exit(1)

        # Only update apt cache if secret service libs are missing
        need_apt = not (command_exists("gnome-keyring") or shutil.which("secret-tool"))
        if need_apt:
            print("\n[+] Installing Secret Service dependencies...")
            run(["sudo", "apt", "update"])
            run(["sudo", "apt", "install", "-y", "libsecret-1-0", "gnome-keyring"])
        else:
            print("\n[i] Secret Service dependencies already present, skipping apt.")

        print("\n[+] Configuring Git identity...")
        run(["git", "config", "--global", "user.name", username])
        run(["git", "config", "--global", "user.email", email])

        print("\n[+] Configuring Git Credential Manager...")
        run(["git", "config", "--global", "credential.helper", "manager"])
        run(["git", "config", "--global", "credential.credentialStore", "secretservice"])

    ensure_keyring_running()

    # Show configuration
    print("\n" + "=" * 60)
    print("                 SETUP COMPLETE")
    print("=" * 60)
    for key, label in [
        ("user.name", "Git username"),
        ("user.email", "Git email"),
        ("credential.credentialStore", "GCM credential store"),
        ("credential.helper", "Git credential helper"),
    ]:
        print(f"\n{label}:")
        print(f"  {get_git_config(key) or '(not set)'}")

    # Detect current repository + branch
    result = subprocess.run(
        ["git", "rev-parse", "--show-toplevel"], capture_output=True, text=True
    )
    print("\n" + "-" * 60)

    if result.returncode == 0:
        repo = result.stdout.strip()
        branch_result = subprocess.run(
            ["git", "branch", "--show-current"], capture_output=True, text=True
        )
        branch = branch_result.stdout.strip() or "main"

        print(f"[+] Current Git repository detected:\n    {repo}")
        print(f"[+] Current branch: {branch}")
        print("\nNext steps:")
        print("    1. Make your changes")
        print("    2. git add .")
        print('    3. git commit -m "your message"')
        print(f"    4. git push origin {branch}")
        print("\n[+] The first push will authenticate through GitHub/GCM.")
        print("[+] Complete the authentication in your browser.")
        print("[+] Do NOT enter your GitHub account password.")
    else:
        print("[!] Current directory is not a Git repository.")
        print("\nYou can later enter your repository and run:")
        print("    git add .")
        print('    git commit -m "your message"')
        print("    git push origin <branch>")

    print("\n" + "=" * 60)
    print("Done. No GitHub password/token was stored in this script.")
    print("=" * 60)


if __name__ == "__main__":
    main()
