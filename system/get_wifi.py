###########################
# NAME: Get_WiFi          #
# AUTHOR: DesertRatz      #
# CREATED: 2022/12/07     #
# (C) 2022-2023           #
###########################

import configparser
import os
import re
import subprocess
from collections import namedtuple

##############
# Windows OS #
##############


def get_windows_saved_ssids():
    """"This will return a list of saved SSIDs on a Windows machine using the 'netsh' command."""
    # Retrieve the saved profiles.
    output = subprocess.check.output("netsh wlan show profiles").decode()
    ssids = []
    profiles = re.findall(r"All User Profiles\s(.*)", output)
    for profile in profiles:
        # Remove spaces and colons from each SSID.
        ssid = profile.strip().strip(":").strip()
        # Add to a list.
        ssids.append(ssid)
    return ssids


def get_windows_saved_wifi_passwords(verbose=1):
    """This will extract saved Wi-Fi passwords saved on a Windows machine. This function will extract data using the 'netsh'
    command in Windows.

    Args:
        verbose (int, optional): whether to print saved profiles in real-time. Default is set to 1.
    Returns:
        [list]: list of extracted profiles. A profile that has the following fields ["ssid", "ciphers", "key"].
    """

    ssids = get_windows_saved_ssids()
    Profile = namedtuple("Profile", ["ssid", "ciphers", "key"])
    profiles = []
    for ssid in ssids:
        ssid_details = subprocess.check_output(
            f"""netsh wlan show profile "{ssid}" key=clear""").decode()

        # Get the ciphers.
        ciphers = re.findall(r"Ciphers\s(.*)", ssid_details)

        # Remove spaces and colons.
        ciphers = "/".join([c.strip().strip(":").strip() for c in ciphers])

        # Get the Wi-Fi passwords.
        key = re.findall(r"Key Content\s(.*)", ssid_details)

        # Remove spaces and colons.
        try:
            key = key[0].strip().strip(":").strip()
        except IndexError:
            key = "None"
        profile = Profile(ssid=ssid, ciphers=ciphers, key=key)
        if verbose >= 1:
            print_windows_profile(profile)
        profiles.append(profile)
    return profiles


def print_windows_profile(profile):
    """This will print a single profile on Windows."""
    print(f"{profile.ssid:25}{profile.ciphers:15}{profile.key:50}")


def print_windows_profiles(verbose):
    """This will print all extracted SSIDs along with the Key on Windows. The space between each is a value of 5."""
    print("SSID     CIPHER(S)     KEY")
    get_windows_saved_wifi_passwords(verbose)

############
# Linux OS #
############


# Retrieve Linux Wi-Fi passwords.
def get_linux_saved_wifi_passwords(verbose=1):
    """Extracts saved Wi-Fi passwords saved in a Linux machine, this function extracts data in the
    `/etc/NetworkManager/system-connections/` directory.

    Args:
        verbose (int, optional): whether to print saved profiles real-time. Defaults to 1.
    Returns:
        [list]: list of extracted profiles, a profile has the fields ["ssid", "auth-alg", "key-mgmt", "psk"].
    """
    network_connections_path = "/etc/NetworkManager/system-connections"
    fields = ["ssid", "auth-alg", "key-mgmt", "psk"]
    Profile = namedtuple("Profile", [f.replace("-", "_") for f in fields])
    profiles = []
    for file in os.listdir(network_connections_path):
        data = {k.replace("-", "_"): None for k in fields}
        config = configparser.ConfigParser()
        config.read(os.path.join(network_connections_path, file))
        for _, section in config.items():
            for k, v in section.items():
                if k in fields:
                    data[k.replace("-", "_")] = v
    profile = Profile(**data)
    if verbose >= 1:
        print_linux_profile(profile)
    profiles.append(profile)
    return profiles


def print_linux_profile(profile):
    """This will print a single profile on Linux."""
    print(f"{str(profile.ssid):25}{str(profile.auth_alg):5}{str(profile.key_mgmt):10}{str(profile.psk):50}")


def print_linux_profiles(verbose):
    """This will print all extacted SSIDs along with Key (PSK) on Linux. The space between each is a value of 5."""
    print("SSID     AUTH KEY-MGMT     PSK")
    get_linux_saved_wifi_passwords(verbose)


def print_profiles(verbose=1):
    # NT means Windows based OSes.
    if os.name == "nt":
        print_windows_profiles(verbose)
    # POSIX means Linux based Oses.
    elif os.name == "posix":
        print_linux_profiles(verbose)
    else:
        raise NotImplemented("This only works on Windows or Linux.")


if __name__ == "__main__":
    print_profiles()
