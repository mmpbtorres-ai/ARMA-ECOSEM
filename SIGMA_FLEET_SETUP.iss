#define MyAppName "SIGMA Fleet Enterprise"
#define MyAppVersion "1.0.0"
#define MyAppPublisher "SIGMA Fleet"
#define MyAppExeName "INICIAR_SIGMA.bat"
[Setup]
AppId={{8B2B1C60-5C62-4A1B-8D1C-72BCE5E10A10}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName={localappdata}\Programs\SIGMA Fleet Enterprise
DefaultGroupName=SIGMA Fleet Enterprise
DisableProgramGroupPage=yes
OutputDir=installer_output
OutputBaseFilename=SIGMA_FLEET_ENTERPRISE_SETUP_V1.0
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=lowest
[Files]
Source: "*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs; Excludes: "node_modules\*,installer_output\*,.git\*"
[Icons]
Name: "{autoprograms}\SIGMA Fleet Enterprise"; Filename: "{app}\INICIAR_SIGMA.bat"; WorkingDir: "{app}"
Name: "{autodesktop}\SIGMA Fleet Enterprise"; Filename: "{app}\INICIAR_SIGMA.bat"; WorkingDir: "{app}"
[Run]
Filename: "powershell.exe"; Parameters: "-NoProfile -ExecutionPolicy Bypass -File ""{app}\CONFIGURAR_WINDOWS.ps1"""; WorkingDir: "{app}"; Flags: postinstall waituntilterminated
