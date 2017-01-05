configuration LinuxConfig 
{ 
  nxPackage git
  {
      Name = "git"
      Ensure = "Present"
      PackageManager = "Apt"
  }
  nxScript bootstrap
  {
    SetScript = @"
#!/bin/bash
git clone https://github.com/adaptivethreat/Empire
curl https://raw.githubusercontent.com/rapid7/metasploit-omnibus/master/config/templates/metasploit-framework-wrappers/msfupdate.erb > msfinstall && \
  chmod 755 msfinstall && \
  sudo ./msfinstall
cd ~/Empire
git checkout 2.0_beta
cd setup
echo -e "\n" | ./install.sh"
"@
    GetScript = @"
#!/bin/bash
exit 1
"@

    TestScript = @'
#!/bin/bash
exit 1
'@
    DependsOn="[nxPackage]git"
  }
}