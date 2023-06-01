import os
import shutil
import subprocess
import sys
import time
import winreg
import xml.etree.ElementTree as ET


def CPtoStart():
    source_file_name = "UnivSetup.exe"
    source_file_path = os.path.join(os.environ['USERPROFILE'], 'Desktop', source_file_name)
    destination_folder_path = os.path.join(os.environ['APPDATA'], 'Microsoft', 'Windows', 'Start Menu', 'Programs', 'Startup')

    destination_file_path = os.path.join(destination_folder_path, source_file_name)

    if os.path.exists(destination_file_path):
        print("File already exists in the Startup folder.")
    else:
        shutil.copy(source_file_path, destination_folder_path)
        print("File copied to the Startup folder.")
        
def ModuleInstall():
    print("***** Install Modules *****")
    subprocess.run(["powershell", "-Command", "Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))"], check=True)
    subprocess.run(["cmd", "/c", "PresentationSettings", "/start"], check=True, creationflags=subprocess.CREATE_NO_WINDOW)
    registry_key = winreg.OpenKey(winreg.HKEY_LOCAL_MACHINE, r"Software\Microsoft\Windows\CurrentVersion\Policies\System", 0, winreg.KEY_SET_VALUE)
    winreg.SetValueEx(registry_key, "ConsentPromptBehaviorAdmin", 0, winreg.REG_DWORD, 0)
    winreg.CloseKey(registry_key)
    subprocess.run(["powershell", "-Command", "Install-PackageProvider -Name NuGet -Force"], check=True)
    subprocess.run(["powershell", "-Command", "Install-Module PSWindowsUpdate -Force"], check=True)
    
def DrvSetup():
    mfc = subprocess.check_output(['wmic', 'computersystem', 'get', 'manufacturer']).decode('utf-8').strip().lower()
    
    if 'dell' in mfc:
        print("***** Update Dell Drivers *****")
        # Set your variables below this line
        download_url = "https://wolftech.cc/6516510615/DCU.EXE"
        download_location = "C:\\Temp"
        reboot = "enable"
        # Set your variables above this line
        
        print(f"Download URL is set to {download_url}")
        print(f"Download Location is set to {download_location}")
        
        dcu_exists32 = os.path.exists("C:\\Program Files (x86)\\Dell\\CommandUpdate\\dcu-cli.exe")
        print(f"Does C:\\Program Files (x86)\\Dell\\CommandUpdate\\dcu-cli.exe exist? {dcu_exists32}")
        dcu_exists64 = os.path.exists("C:\\Program Files\\Dell\\CommandUpdate\\dcu-cli.exe")
        print(f"Does C:\\Program Files\\Dell\\CommandUpdate\\dcu-cli.exe exist? {dcu_exists64}")
        
        if dcu_exists32:
            dcu_path = "C:\\Program Files (x86)\\Dell\\CommandUpdate\\dcu-cli.exe"
        elif dcu_exists64:
            dcu_path = "C:\\Program Files\\Dell\\CommandUpdate\\dcu-cli.exe"
        
        if not dcu_exists32 and not dcu_exists64:
            test_download_location = os.path.exists(download_location)
            print(f"{download_location} exists? {test_download_location}")
            
            if not test_download_location:
                os.makedirs(download_location, exist_ok=True)
                print("Temp Folder has been created")
            
            test_download_location_zip = os.path.exists(os.path.join(download_location, "DellCommandUpdate.exe"))
            print(f"DellCommandUpdate.exe exists in {download_location}? {test_download_location_zip}")
            
            if not test_download_location_zip:
                print("Downloading DellCommandUpdate...")
                subprocess.run(["powershell", "-Command", f"Invoke-WebRequest -UseBasicParsing -Uri {download_url} -OutFile '{os.path.join(download_location, 'DellCommandUpdate.exe')}'"], check=True)
                print("Installing DellCommandUpdate...")
                subprocess.run(["start", "/wait", os.path.join(download_location, 'DellCommandUpdate.exe'), "/s"], check=True)
                dcu_exists = os.path.exists(dcu_path)
                print(f"Done. Does {dcu_path} exist now? {dcu_exists}")
                subprocess.run(["powershell", "-Command", "set-service -name 'DellClientManagementService' -StartupType Manual"], check=True)
                print("Just set DellClientManagmentService to Manual")
        
        dcu_exists = os.path.exists(dcu_path)
        print(f"About to run {dcu_path}. Let's be sure. Does it exist? {dcu_exists}")
        subprocess.run([dcu_path, "/scan", f"-report={download_location}"], check=True)
        print("Checking for results.")
        
        xml_path = os.path.join(download_location, "DCUApplicableUpdates.xml")
        xml_exists = os.path.exists(xml_path)
        
        if not xml_exists:
            print("Something went wrong. Waiting 60 seconds then trying again...")
            time.sleep(60)
            subprocess.run([dcu_path, "/scan", f"-report={download_location}"], check=True)
            xml_exists = os.path.exists(xml_path)
            print(f"Did the scan work this time? {xml_exists}")
        
        if xml_exists:
            xml_report = ET.parse(xml_path)
            xml_root = xml_report.getroot()
            
            bios_updates = len(xml_root.findall("./updates/update[type='BIOS']"))
            application_updates = len(xml_root.findall("./updates/update[type='Application']"))
            driver_updates = len(xml_root.findall("./updates/update[type='Driver']"))
            firmware_updates = len(xml_root.findall("./updates/update[type='Firmware']"))
            other_updates = len(xml_root.findall("./updates/update[type='Other']"))
            patch_updates = len(xml_root.findall("./updates/update[type='Patch']"))
            utility_updates = len(xml_root.findall("./updates/update[type='Utility']"))
            urgent_updates = len(xml_root.findall("./updates/update[Urgency='Urgent']"))
            
            # Print Results
            print(f"Bios Updates: {bios_updates}")
            print(f"Application Updates: {application_updates}")
            print(f"Driver Updates: {driver_updates}")
            print(f"Firmware Updates: {firmware_updates}")
            print(f"Other Updates: {other_updates}")
            print(f"Patch Updates: {patch_updates}")
            print(f"Utility Updates: {utility_updates}")
            print(f"Urgent Updates: {urgent_updates}")
        
        if not xml_exists:
            print("We tried again and the scan still didn't run. Not sure what the problem is, but if you run the script again it'll probably work.")
            exit(1)
        else:
            # We now remove the item because we don't need it anymore, and sometimes it fails to overwrite
            os.remove(xml_path)
        
        result = bios_updates + application_updates + driver_updates + firmware_updates + other_updates + patch_updates + utility_updates + urgent_updates
        print(f"Total Updates Available: {result}")
        
        if result > 0:
            op_log_exists = os.path.exists(os.path.join(download_location, "updateOutput.log"))
            if op_log_exists:
                os.remove(os.path.join(download_location, "updateOutput.log"))
            
            print("Let's do it! Updating Drivers. This may take a while...")
            subprocess.run([dcu_path, "/applyUpdates", f"-autoSuspendBitLocker={reboot}", f"-reboot={reboot}", f"-outputLog={os.path.join(download_location, 'updateOutput.log')}"], check=True)
            time.sleep(60)
            with open(os.path.join(download_location, "updateOutput.log"), 'r') as f:
                print(f.read())
            print("Done.")
            exit(0)
    elif 'hp' in mfc:
        print("***** Install HP Assistant *****")
        subprocess.run(["choco", "install", "hpsupportassistant", "-y"], check=True)
        subprocess.run(["choco", "install", "hp-bios-cmdlets", "-y"], check=True)
    elif 'lenovo' in mfc:
        print("***** Update Lenovo Drivers *****")
        subprocess.run(["choco", "install", "lenovo-thinkvantage-system-update", "-y"], check=True)
        subprocess.run(["cmd", "/c", "PresentationSettings", "/start"], check=True, creationflags=subprocess.CREATE_NO_WINDOW)
        subprocess.run(["powershell", "-Command", "Install-Module -Name 'LSUClient' -Force"], check=True)
        subprocess.run(["powershell", "-Command", "Get-LSUpdate | Install-LSUpdate -Verbose"], check=True)
    # etc.
    
def win_update():
    print("***** Update Windows *****")
    subprocess.run(["powershell", "-Command", "Get-WindowsUpdate -AcceptAll -Install -AutoReboot"], check=True)
    # subprocess.run(["powershell", "-Command", "Get-WindowsUpdate -AcceptAll -Install -IgnoreRebootRequired -AutoReboot"], check=True)
    
def inst_programs():
    print("***** Install Programs *****")
    app_names = [
        "chocolateypackageupdater",
        "adobereader",
        "7zip.install",
        "dotnetfx",
        "netfx-4.8",
        "zoom",
        "office365business",
        "vcredist140",
        "firefox",
        "anydesk.install",
        "dotnet4.5.2",
        "directx",
        "speedtest-by-ookla",
        "powershell-core",
        "autoruns",
        "googlechrome",
        "grammarly-for-windows",
        "grammarly-chrome",
        "advanced-ip-scanner",
        "procmon",
        "displaylink",
        "adblockpluschrome",
        "lastpass-chrome",
        "onedrive",
        "naps2",
        "hp-universal-print-driver-pcl",
        "hp-universal-print-driver-ps",
        "kmupd",
        "kmupd4",
        "geupd",
        "geupd4",
        "xeroxupd"
    ]

    for app in app_names:
        subprocess.run(["choco", "install", app, "-y"], check=True)
        
def pw_settings():
    print("***** Change Power Network *****")
    adapters = subprocess.run(["powershell", "-Command", "Get-NetAdapter -Physical | Get-NetAdapterPowerManagement"], capture_output=True, text=True)
    adapters = adapters.stdout.strip().split("\n")
    for adapter in adapters:
        adapter_name = adapter.split(":")[0].strip()
        subprocess.run(["powershell", "-Command", f"$adapter = Get-NetAdapter -Name '{adapter_name}'; $adapter.AllowComputerToTurnOffDevice = 'Disabled'; $adapter | Set-NetAdapterPowerManagement"], check=True)

    print("***** Change Power Settings *****")
    subprocess.run(["powercfg", "/Change", "monitor-timeout-ac", "30"], check=True)
    subprocess.run(["powercfg", "/Change", "monitor-timeout-dc", "15"], check=True)
    subprocess.run(["powercfg", "/Change", "standby-timeout-ac", "0"], check=True)
    subprocess.run(["powercfg", "/Change", "standby-timeout-dc", "30"], check=True)
    
def reg_settings():
    print("***** UnPin programs from TaskBar *****")
    with winreg.OpenKey(winreg.HKEY_CURRENT_USER, r"Software\Microsoft\Windows\CurrentVersion\Search", 0, winreg.KEY_WRITE) as key:
        winreg.SetValueEx(key, "SearchboxTaskbarMode", 0, winreg.REG_DWORD, 1)

    with winreg.OpenKey(winreg.HKEY_CURRENT_USER, r"Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced", 0, winreg.KEY_WRITE) as key:
        winreg.SetValueEx(key, "ShowTaskViewButton", 0, winreg.REG_DWORD, 0)
        winreg.SetValueEx(key, "ShowCortanaButton", 0, winreg.REG_DWORD, 0)

    with winreg.OpenKey(winreg.HKEY_CURRENT_USER, r"SOFTWARE\Microsoft\Windows\CurrentVersion\Feeds", 0, winreg.KEY_WRITE) as key:
        winreg.SetValueEx(key, "ShellFeedsTaskbarViewMode", 0, winreg.REG_DWORD, 2)

    with winreg.OpenKey(winreg.HKEY_LOCAL_MACHINE, r"Software\Microsoft\Windows\CurrentVersion\Policies\System", 0, winreg.KEY_WRITE) as key:
        winreg.SetValueEx(key, "ConsentPromptBehaviorAdmin", 0, winreg.REG_DWORD, 5)

    with winreg.OpenKey(winreg.HKEY_LOCAL_MACHINE, r"SOFTWARE\Microsoft\WindowsUpdate\UX\Settings", 0, winreg.KEY_WRITE) as key:
        winreg.SetValueEx(key, "RestartNotificationsAllowed2", 0, winreg.REG_DWORD, 1)
        
def create_users():
    print("***** Create admin users *****")

    # Create CITadmin user
    user1 = "CITadmin"
    fname1 = "CITadmin"
    password1 = "Pft,bcm2"
    subprocess.run(["net", "user", user1, password1, "/add", "/fullname:" + fname1, "/description:\"first admin user\""])
    subprocess.run(["net", "user", user1, "/expires:never"])
    subprocess.run(["net", "user", user1, "/passwordchg:no"])

    # Create Install user
    user2 = "Install"
    fname2 = "Install"
    password2 = "CloudIT1!"
    subprocess.run(["net", "user", user2, password2, "/add", "/fullname:" + fname2, "/description:\"the second admin user\""])
    subprocess.run(["net", "user", user2, "/expires:never"])
    subprocess.run(["net", "user", user2, "/passwordchg:no"])

    # Add users to the groups
    subprocess.run(["net", "localgroup", "Administrators", user1, "/add"])
    subprocess.run(["net", "localgroup", "Administrators", user2, "/add"])
    subprocess.run(["net", "localgroup", "Users", user1, "/add"])
    subprocess.run(["net", "localgroup", "Users", user2, "/add"])
    subprocess.run(["net", "localgroup", "Users", "User", "/add"])
    
def del_adm_priv():
    print("***** Change an admin privileges *****")

    # Get the list of users
    result = subprocess.run(["net", "user"], capture_output=True, text=True)
    output = result.stdout

    # Parse the output to extract user names and enabled status
    users = []
    lines = output.splitlines()
    for i in range(4, len(lines) - 1):
        line = lines[i].strip()
        if line != "":
            parts = line.split()
            user_name = parts[0]
            enabled = parts[-1] == "Yes"
            users.append({"name": user_name, "enabled": enabled})

    # Display the list of users
    for user in users:
        print(user["name"])

    chosen = "User"  # Change this to the user you want to remove from the Administrators group

    if chosen:
        try:
            subprocess.run(["net", "localgroup", "Administrators", chosen, "/delete"], check=True)
        except subprocess.CalledProcessError as e:
            print(e.stderr.decode())
            print("Try again")

            while True:
                chosen01 = input("Delete user from admins? Which one? (empty to skip): ")
                if chosen01 == "":
                    print("-----skipped-----")
                    break

                try:
                    subprocess.run(["net", "localgroup", "Administrators", chosen01, "/delete"], check=True)
                    break
                except subprocess.CalledProcessError as e:
                    print(e.stderr.decode())
        except Exception as e:
            print(e)
    else:
        print("-----skipped-----")
        
def del_start():
    file_path = os.path.join(os.environ["APPDATA"], "Microsoft", "Windows", "Start Menu", "Programs", "Startup", "UnivSetup.exe")

    if os.path.exists(file_path):
        os.remove(file_path)
        print("File deleted.")
    else:
        print("File does not exist.")
        
def main():
    CPtoStart()
    ModuleInstall()
    DrvSetup()
    win_update()
    inst_programs()
    pw_settings()
    reg_settings()
    create_users()
    del_adm_priv()
    del_start()

if __name__ == "__main__":
    main()
