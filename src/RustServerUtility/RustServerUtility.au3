#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=..\..\resources\favicon.ico
#AutoIt3Wrapper_Outfile=..\..\build\RustServerUtility_x86_v1.0.0-rc.3.exe
#AutoIt3Wrapper_Outfile_x64=..\..\build\RustServerUtility_x64_v1.0.0-rc.3.exe
#AutoIt3Wrapper_Compile_Both=y
#AutoIt3Wrapper_UseX64=y
#AutoIt3Wrapper_Res_Comment=By Dateranoth - August 13, 2017
#AutoIt3Wrapper_Res_Description=Utility for Running Rust Server
#AutoIt3Wrapper_Res_Fileversion=1.0.0.0
#AutoIt3Wrapper_Res_LegalCopyright=Dateranoth @ https://gamercide.com
#AutoIt3Wrapper_Res_Language=1033
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
;Originally written by Dateranoth for use
;by https://gamercide.com on their server
;Distributed Under GNU GENERAL PUBLIC LICENSE

#include <Date.au3>

#Region ;**** UnZip Function by trancexx ****
; #FUNCTION# ;===============================================================================
;
; Name...........: _ExtractZip
; Description ...: Extracts file/folder from ZIP compressed file
; Syntax.........: _ExtractZip($sZipFile, $sFolderStructure, $sFile, $sDestinationFolder)
; Parameters ....: $sZipFile - full path to the ZIP file to process
;                  $sFolderStructure - 'path' to the file/folder to extract inside ZIP file
;                  $sFile - file/folder to extract
;                  $sDestinationFolder - folder to extract to. Must exist.
; Return values .: Success - Returns 1
;                          - Sets @error to 0
;                  Failure - Returns 0 sets @error:
;                  |1 - Shell Object creation failure
;                  |2 - Destination folder is unavailable
;                  |3 - Structure within ZIP file is wrong
;                  |4 - Specified file/folder to extract not existing
; Author ........: trancexx
; https://www.autoitscript.com/forum/topic/101529-sunzippings-zipping/#comment-721866
;
;==========================================================================================
Func _ExtractZip($sZipFile, $sFolderStructure, $sFile, $sDestinationFolder)

	Local $i
	Do
		$i += 1
		$sTempZipFolder = @TempDir & "\Temporary Directory " & $i & " for " & StringRegExpReplace($sZipFile, ".*\\", "")
	Until Not FileExists($sTempZipFolder) ; this folder will be created during extraction

	Local $oShell = ObjCreate("Shell.Application")

	If Not IsObj($oShell) Then
		Return SetError(1, 0, 0) ; highly unlikely but could happen
	EndIf

	Local $oDestinationFolder = $oShell.NameSpace($sDestinationFolder)
	If Not IsObj($oDestinationFolder) Then
		Return SetError(2, 0, 0) ; unavailable destionation location
	EndIf

	Local $oOriginFolder = $oShell.NameSpace($sZipFile & "\" & $sFolderStructure) ; FolderStructure is overstatement because of the available depth
	If Not IsObj($oOriginFolder) Then
		Return SetError(3, 0, 0) ; unavailable location
	EndIf

	;Local $oOriginFile = $oOriginFolder.Items.Item($sFile)
	Local $oOriginFile = $oOriginFolder.ParseName($sFile)
	If Not IsObj($oOriginFile) Then
		Return SetError(4, 0, 0) ; no such file in ZIP file
	EndIf

	; copy content of origin to destination
	$oDestinationFolder.CopyHere($oOriginFile, 4) ; 4 means "do not display a progress dialog box", but apparently doesn't work

	DirRemove($sTempZipFolder, 1) ; clean temp dir

	Return 1 ; All OK!

EndFunc   ;==>_ExtractZip
#EndRegion ;**** UnZip Function by trancexx ****


#Region ;**** Global Variables ****
Global $g_sTimeCheck0 = _NowCalc()
Global $g_sTimeCheck1 = _NowCalc()
Global $g_sTimeCheck2 = _NowCalc()
Global $g_sTimeCheck3 = _NowCalc()
Global $g_sTimeCheck4 = _NowCalc()
Global Const $g_c_sServerEXE = "RustDedicated.exe"
Global Const $g_c_sPIDFile = @ScriptDir & "\RustServerUtility_lastpid_tmp"
Global Const $g_c_sHwndFile = @ScriptDir & "\RustServerUtility_lasthwnd_tmp"
Global Const $g_c_sSeedFile = @ScriptDir & "\RustServerUtility_SeedLog.ini"
Global Const $g_c_sLogFile = @ScriptDir & "\RustServerUtility.log"
Global Const $g_c_sIniFile = @ScriptDir & "\RustServerUtility.ini"
Global $g_iIniFail = 0
Global $g_iBeginDelayedShutdown = 0
Global $g_sRCONp = ""

If FileExists($g_c_sPIDFile) Then
	Global $g_sRustPID = FileRead($g_c_sPIDFile)
Else
	Global $g_sRustPID = "0"
EndIf
If FileExists($g_c_sHwndFile) Then
	Global $g_hRusthWnd = HWnd(FileRead($g_c_sHwndFile))
Else
	Global $g_hRusthWnd = "0"
EndIf
#EndRegion ;**** Global Variables ****



#Region ;**** INI Settings - User Variables ****
Func ReadUini()
	Local $iniCheck = ""
	Local $aChar[3]
	For $i = 1 To 13
		$aChar[0] = Chr(Random(97, 122, 1)) ;a-z
		$aChar[1] = Chr(Random(48, 57, 1)) ;0-9
		$iniCheck &= $aChar[Random(0, 1, 1)]
	Next

	Global $g_sServerDir = IniRead($g_c_sIniFile, "Server Settings", "ServerDirectory", $iniCheck)
	Global $g_sServerIdentity = IniRead($g_c_sIniFile, "Server Settings", "ServerIdentity", $iniCheck)
	Global $g_sServerIP = IniRead($g_c_sIniFile, "Server Settings", "ServerIP", $iniCheck)
	Global $g_sServerPort = IniRead($g_c_sIniFile, "Server Settings", "ServerPort", $iniCheck)
	Global $g_sServerHostName = IniRead($g_c_sIniFile, "Server Settings", "ServerHostName", $iniCheck)
	Global $g_sMaxPlayers = IniRead($g_c_sIniFile, "Server Settings", "MaxPlayers", $iniCheck)
	Global $g_sWorldSize = IniRead($g_c_sIniFile, "Server Settings", "WorldSize", $iniCheck)
	Global $g_sSeed = IniRead($g_c_sIniFile, "Server Settings", "WorldSeed", $iniCheck)
	Global $g_sSaveInterval = IniRead($g_c_sIniFile, "Server Settings", "SaveInterval", $iniCheck)
	Global $g_sTickRate = IniRead($g_c_sIniFile, "Server Settings", "TickRate", $iniCheck)
	Global $g_sServerHeaderImage = IniRead($g_c_sIniFile, "Server Settings", "ServerHeaderImage", $iniCheck)
	Global $g_sServerURL = IniRead($g_c_sIniFile, "Server Settings", "ServerURL", $iniCheck)
	Global $g_sServerDescription = IniRead($g_c_sIniFile, "Server Settings", "ServerDescription", $iniCheck)
	Global $g_sRCONIP = IniRead($g_c_sIniFile, "RCON Settings", "RCONIP", $iniCheck)
	Global $g_sRCONPort = IniRead($g_c_sIniFile, "RCON Settings", "RCONPort", $iniCheck)
	Global $g_sRCONPass = IniRead($g_c_sIniFile, "RCON Settings", "RCONPass", $iniCheck)
	Global $g_sMonthlyWipes = IniRead($g_c_sIniFile, "Wipe by generating new random seed the first Thursday of each Month? yes/no", "MonthlyWipes", $iniCheck)
	Global $g_sUseSteamCMD = IniRead($g_c_sIniFile, "Use SteamCMD To Update Server? yes/no", "UseSteamCMD", $iniCheck)
	Global $g_sSteamCmdDir = IniRead($g_c_sIniFile, "Use SteamCMD To Update Server? yes/no", "SteamCmdDir", $iniCheck)
	Global $g_sValidateGame = IniRead($g_c_sIniFile, "Use SteamCMD To Update Server? yes/no", "ValidateGameFiles", $iniCheck)
	Global $g_sUseRemoteRestart = IniRead($g_c_sIniFile, "Use Remote Restart ?yes/no", "UseRemoteRestart", $iniCheck)
	Global $g_sRestartPort = IniRead($g_c_sIniFile, "Use Remote Restart ?yes/no", "RestartPort", $iniCheck)
	Global $g_sRestartUser_Password = IniRead($g_c_sIniFile, "Use Remote Restart ?yes/no", "RestartUser_Password", $iniCheck)
	Global $g_sObfuscatePass = IniRead($g_c_sIniFile, "Hide Passwords in Log? yes/no", "ObfuscatePass", $iniCheck)
	Global $g_sCheckForUpdate = IniRead($g_c_sIniFile, "Check for Update Every X Minutes? yes/no", "CheckForUpdate", $iniCheck)
	Global $g_sUpdateInterval = IniRead($g_c_sIniFile, "Update Check Interval in Minutes 05-59", "UpdateInterval", $iniCheck)
	Global $g_sUseOxide = IniRead($g_c_sIniFile, "Install Oxide and Update with Server? yes/no", "UseOxide", $iniCheck)
	Global $g_sRestartDaily = IniRead($g_c_sIniFile, "Restart Server at Set Time? yes/no", "RestartDaily", $iniCheck)
	Global $g_sRestartHour1 = IniRead($g_c_sIniFile, "Daily Restart Hours? 00-23", "RestartHour1", $iniCheck)
	Global $g_sRestartHour2 = IniRead($g_c_sIniFile, "Daily Restart Hours? 00-23", "RestartHour2", $iniCheck)
	Global $g_sRestartHour3 = IniRead($g_c_sIniFile, "Daily Restart Hours? 00-23", "RestartHour3", $iniCheck)
	Global $g_sRestartHour4 = IniRead($g_c_sIniFile, "Daily Restart Hours? 00-23", "RestartHour4", $iniCheck)
	Global $g_sRestartHour5 = IniRead($g_c_sIniFile, "Daily Restart Hours? 00-23", "RestartHour5", $iniCheck)
	Global $g_sRestartHour6 = IniRead($g_c_sIniFile, "Daily Restart Hours? 00-23", "RestartHour6", $iniCheck)
	Global $g_sRestartMinute = IniRead($g_c_sIniFile, "Daily Restart Minute? 00-59", "RestartMinute", $iniCheck)
	Global $g_sExMem = IniRead($g_c_sIniFile, "Excessive Memory Amount? in GB", "ExMem", $iniCheck)
	Global $g_sExMemRestart = IniRead($g_c_sIniFile, "Restart On Excessive Memory Use? yes/no", "ExMemRestart", $iniCheck)
	Global $g_sRotateLogs = IniRead($g_c_sIniFile, "Rotate X Number of Logs every X Hours? yes/no", "RotateLogs", $iniCheck)
	Global $g_sLogQuantity = IniRead($g_c_sIniFile, "Rotate X Number of Logs every X Hours? yes/no", "LogQuantity", $iniCheck)
	Global $g_sLogHoursBetweenRotate = IniRead($g_c_sIniFile, "Rotate X Number of Logs every X Hours? yes/no", "LogHoursBetweenRotate", $iniCheck)
	Global $g_sUseDiscordBot = IniRead($g_c_sIniFile, "Use Discord Bot to Send Message Before Restart? yes/no", "UseDiscordBot", $iniCheck)
	Global $g_sDiscordWebHookURLs = IniRead($g_c_sIniFile, "Use Discord Bot to Send Message Before Restart? yes/no", "DiscordWebHookURL", $iniCheck)
	Global $g_sDiscordBotName = IniRead($g_c_sIniFile, "Use Discord Bot to Send Message Before Restart? yes/no", "DiscordBotName", $iniCheck)
	Global $g_sDiscordBotUseTTS = IniRead($g_c_sIniFile, "Use Discord Bot to Send Message Before Restart? yes/no", "DiscordBotUseTTS", $iniCheck)
	Global $g_sDiscordBotAvatar = IniRead($g_c_sIniFile, "Use Discord Bot to Send Message Before Restart? yes/no", "DiscordBotAvatarLink", $iniCheck)
	Global $g_sUseTwitchBot = IniRead($g_c_sIniFile, "Use Twitch Bot to Send Message Before Restart? yes/no", "UseTwitchBot", $iniCheck)
	Global $g_sTwitchNick = IniRead($g_c_sIniFile, "Use Twitch Bot to Send Message Before Restart? yes/no", "TwitchNick", $iniCheck)
	Global $g_sChatOAuth = IniRead($g_c_sIniFile, "Use Twitch Bot to Send Message Before Restart? yes/no", "ChatOAuth", $iniCheck)
	Global $g_sTwitchChannels = IniRead($g_c_sIniFile, "Use Twitch Bot to Send Message Before Restart? yes/no", "TwitchChannels", $iniCheck)
	Global $g_sNotifyInGame = IniRead($g_c_sIniFile, "Send Message to in Game Players Before Restart? yes/no", "NotifyInGame", $iniCheck)
	Global $g_iDelayShutdownTime = IniRead($g_c_sIniFile, "Set the Delay Time Before Restarting when using any Notification Method (minutes)", "TimeBeforeRestart", $iniCheck)

	If $iniCheck = $g_sServerDir Then
		$g_sServerDir = "C:\Game_Servers\Rust_Server"
		$g_iIniFail += 1
	EndIf
	If $iniCheck = $g_sServerIdentity Then
		$g_sServerIdentity = "my_server_identity"
		$g_iIniFail += 1
	EndIf
	If $iniCheck = $g_sServerIP Then
		$g_sServerIP = "0.0.0.0"
		$g_iIniFail += 1
	EndIf
	If $iniCheck = $g_sServerPort Then
		$g_sServerPort = "28015"
		$g_iIniFail += 1
	EndIf
	If $iniCheck = $g_sServerHostName Then
		$g_sServerHostName = "My Untitled Rust Server"
		$g_iIniFail += 1
	EndIf
	If $iniCheck = $g_sMaxPlayers Then
		$g_sMaxPlayers = "500"
		$g_iIniFail += 1
	EndIf
	If $iniCheck = $g_sWorldSize Then
		$g_sWorldSize = "3500"
		$g_iIniFail += 1
	EndIf
	If $iniCheck = $g_sSeed Then
		$g_sSeed = Random(1, 2147483647, 1)
		$g_iIniFail += 1
	EndIf
	If $iniCheck = $g_sSaveInterval Then
		$g_sSaveInterval = "600"
		$g_iIniFail += 1
	EndIf
	If $iniCheck = $g_sTickRate Then
		$g_sTickRate = "10"
		$g_iIniFail += 1
	EndIf
	If $iniCheck = $g_sServerHeaderImage Then
		$g_sServerHeaderImage = "https://playrust.com/wp-content/uploads/2013/12/RustLogo-Normal-Transparent.png"
		$g_iIniFail += 1
	EndIf
	If $iniCheck = $g_sServerURL Then
		$g_sServerURL = "https://playrust.com/"
		$g_iIniFail += 1
	EndIf
	If $iniCheck = $g_sServerDescription Then
		$g_sServerDescription = "Dateranoth's Rust Server Utility keeps this server running."
		$g_iIniFail += 1
	EndIf

	If $iniCheck = $g_sRCONIP Then
		$g_sRCONIP = "127.0.0.1"
		$g_iIniFail += 1
	EndIf
	If $iniCheck = $g_sRCONPort Then
		$g_sRCONPort = "28016"
		$g_iIniFail += 1
	EndIf
	If $iniCheck = $g_sRCONPass Then
		$g_sRCONPass &= "_RANDOM"
		$g_iIniFail += 1
	EndIf
	If $iniCheck = $g_sMonthlyWipes Then
		$g_sMonthlyWipes = "no"
		$g_iIniFail += 1
	EndIf
	If $iniCheck = $g_sUseSteamCMD Then
		$g_sUseSteamCMD = "yes"
		$g_iIniFail += 1
	EndIf
	If $iniCheck = $g_sSteamCmdDir Then
		$g_sSteamCmdDir = "C:\Game_Servers\SteamCMD"
		$g_iIniFail += 1
	EndIf
	If $iniCheck = $g_sValidateGame Then
		$g_sValidateGame = "no"
		$g_iIniFail += 1
	EndIf
	If $iniCheck = $g_sUseRemoteRestart Then
		$g_sUseRemoteRestart = "no"
		$g_iIniFail += 1
	EndIf
	If $iniCheck = $g_sRestartPort Then
		$g_sRestartPort = "57530"
		$g_iIniFail += 1
	EndIf
	If $iniCheck = $g_sRestartUser_Password Then
		$g_sRestartUser_Password = "Admin1_" & $g_sRestartUser_Password
		$g_iIniFail += 1
	EndIf
	If $iniCheck = $g_sObfuscatePass Then
		$g_sObfuscatePass = "yes"
		$g_iIniFail += 1
	EndIf
	If $iniCheck = $g_sCheckForUpdate Then
		$g_sCheckForUpdate = "yes"
		$g_iIniFail += 1
	ElseIf $g_sCheckForUpdate = "yes" And $g_sUseSteamCMD <> "yes" Then
		$g_sCheckForUpdate = "no"
		FileWriteLine($g_c_sLogFile, _NowCalc() & " SteamCMD disabled. Disabling CheckForUpdate. Update will not work without SteamCMD to update it!")
	EndIf
	If $iniCheck = $g_sUpdateInterval Then
		$g_sUpdateInterval = "15"
		$g_iIniFail += 1
	ElseIf $g_sUpdateInterval < 5 Then
		$g_sUpdateInterval = 5
	EndIf
	If $iniCheck = $g_sUseOxide Then
		$g_sUseOxide = "no"
		$g_iIniFail += 1
	EndIf
	If $iniCheck = $g_sRestartDaily Then
		$g_sRestartDaily = "no"
		$g_iIniFail += 1
	EndIf
	If $iniCheck = $g_sRestartHour1 Then
		$g_sRestartHour1 = "00"
		$g_iIniFail += 1
	EndIf
	If $iniCheck = $g_sRestartHour2 Then
		$g_sRestartHour2 = "00"
		$g_iIniFail += 1
	EndIf
	If $iniCheck = $g_sRestartHour3 Then
		$g_sRestartHour3 = "00"
		$g_iIniFail += 1
	EndIf
	If $iniCheck = $g_sRestartHour4 Then
		$g_sRestartHour4 = "00"
		$g_iIniFail += 1
	EndIf
	If $iniCheck = $g_sRestartHour5 Then
		$g_sRestartHour5 = "00"
		$g_iIniFail += 1
	EndIf
	If $iniCheck = $g_sRestartHour6 Then
		$g_sRestartHour6 = "00"
		$g_iIniFail += 1
	EndIf
	If $iniCheck = $g_sRestartMinute Then
		$g_sRestartMinute = "01"
		$g_iIniFail += 1
	EndIf
	If $iniCheck = $g_sExMem Then
		$g_sExMem = "6"
		$g_iIniFail += 1
	EndIf
	If $iniCheck = $g_sExMemRestart Then
		$g_sExMemRestart = "no"
		$g_iIniFail += 1
	EndIf
	If $iniCheck = $g_sRotateLogs Then
		$g_sRotateLogs = "yes"
		$g_iIniFail += 1
	EndIf
	If $iniCheck = $g_sLogQuantity Then
		$g_sLogQuantity = "10"
		$g_iIniFail += 1
	EndIf
	If $iniCheck = $g_sLogHoursBetweenRotate Then
		$g_sLogHoursBetweenRotate = "24"
		$g_iIniFail += 1
	ElseIf $g_sLogHoursBetweenRotate < 1 Then
		$g_sLogHoursBetweenRotate = 1
	EndIf
	If $iniCheck = $g_sUseDiscordBot Then
		$g_sUseDiscordBot = "no"
		$g_iIniFail += 1
	EndIf
	If $iniCheck = $g_sDiscordWebHookURLs Then
		$g_sDiscordWebHookURLs = "https://discordapp.com/api/webhooks/XXXXXX/XXXX <- NO TRAILING SLASH AND USE FULL URL FROM WEBHOOK URL ON DISCORD"
		$g_iIniFail += 1
	EndIf
	If $iniCheck = $g_sDiscordBotName Then
		$g_sDiscordBotName = "Rust Discord Bot"
		$g_iIniFail += 1
	EndIf
	If $iniCheck = $g_sDiscordBotUseTTS Then
		$g_sDiscordBotUseTTS = "yes"
		$g_iIniFail += 1
	EndIf
	If $iniCheck = $g_sDiscordBotAvatar Then
		$g_sDiscordBotAvatar = ""
		$g_iIniFail += 1
	EndIf
	If $iniCheck = $g_sUseTwitchBot Then
		$g_sUseTwitchBot = "no"
		$g_iIniFail += 1
	EndIf
	If $iniCheck = $g_sTwitchNick Then
		$g_sTwitchNick = "twitchbotusername"
		$g_iIniFail += 1
	EndIf
	If $iniCheck = $g_sChatOAuth Then
		$g_sChatOAuth = "oauth:1234 (Generate OAuth Token Here: https://twitchapps.com/tmi)"
		$g_iIniFail += 1
	EndIf
	If $iniCheck = $g_sTwitchChannels Then
		$g_sTwitchChannels = "channel1,channel2,channel3"
		$g_iIniFail += 1
	EndIf
	If $iniCheck = $g_sNotifyInGame Then
		$g_sNotifyInGame = "no"
		$g_iIniFail += 1
	EndIf
	If $iniCheck = $g_iDelayShutdownTime Then
		$g_iDelayShutdownTime = "5"
		$g_iIniFail += 1
	ElseIf $g_iDelayShutdownTime < 1 Then
		$g_iDelayShutdownTime = 1
	EndIf
	If $g_iIniFail > 0 Then
		iniFileCheck()
	EndIf

	If $g_sDiscordBotUseTTS = "yes" Then
		$g_sDiscordBotUseTTS = True
	Else
		$g_sDiscordBotUseTTS = False
	EndIf
	If $g_sMonthlyWipes = "yes" Then
		Global $g_sLastWipeDate = IniRead($g_c_sSeedFile, "Last Wipe Date", "DateofWipe", $iniCheck)
		If $iniCheck = $g_sLastWipeDate Then
			$g_sLastWipeDate = _NowCalc()
			IniWrite($g_c_sSeedFile, "Last Wipe Date", "DateofWipe", $g_sLastWipeDate)
			IniWrite($g_c_sSeedFile, "Seed Log", $g_sLastWipeDate & " ServerSeed", $g_sSeed)
		EndIf
	EndIf
EndFunc   ;==>ReadUini

Func iniFileCheck()
	If FileExists($g_c_sIniFile) Then
		Local $aMyDate, $aMyTime
		_DateTimeSplit(_NowCalc(), $aMyDate, $aMyTime)
		Local $iniDate = StringFormat("%04i.%02i.%02i.%02i%02i", $aMyDate[1], $aMyDate[2], $aMyDate[3], $aMyTime[1], $aMyTime[2])
		FileMove($g_c_sIniFile, $g_c_sIniFile & "_" & $iniDate & ".bak", 1)
		UpdateIni()
		MsgBox(4096, "INI MISMATCH", "Found " & $g_iIniFail & " Missing Variables" & @CRLF & @CRLF & "Backup created and all existing settings transfered to new INI." & @CRLF & @CRLF & "Modify INI and restart.")
		Exit
	Else
		UpdateIni()
		MsgBox(4096, "Default INI File Made", "Please Modify Default Values and Restart Script")
		Exit
	EndIf
EndFunc   ;==>iniFileCheck

Func UpdateIni()

	IniWrite($g_c_sIniFile, "Server Settings", "ServerDirectory", $g_sServerDir)
	IniWrite($g_c_sIniFile, "Server Settings", "ServerIdentity", $g_sServerIdentity)
	IniWrite($g_c_sIniFile, "Server Settings", "ServerIP", $g_sServerIP)
	IniWrite($g_c_sIniFile, "Server Settings", "ServerPort", $g_sServerPort)
	IniWrite($g_c_sIniFile, "Server Settings", "ServerHostName", $g_sServerHostName)
	IniWrite($g_c_sIniFile, "Server Settings", "MaxPlayers", $g_sMaxPlayers)
	IniWrite($g_c_sIniFile, "Server Settings", "WorldSize", $g_sWorldSize)
	IniWrite($g_c_sIniFile, "Server Settings", "WorldSeed", $g_sSeed)
	IniWrite($g_c_sIniFile, "Server Settings", "SaveInterval", $g_sSaveInterval)
	IniWrite($g_c_sIniFile, "Server Settings", "TickRate", $g_sTickRate)
	IniWrite($g_c_sIniFile, "Server Settings", "ServerHeaderImage", $g_sServerHeaderImage)
	IniWrite($g_c_sIniFile, "Server Settings", "ServerURL", $g_sServerURL)
	IniWrite($g_c_sIniFile, "Server Settings", "ServerDescription", $g_sServerDescription)
	IniWrite($g_c_sIniFile, "RCON Settings", "RCONIP", $g_sRCONIP)
	IniWrite($g_c_sIniFile, "RCON Settings", "RCONPort", $g_sRCONPort)
	IniWrite($g_c_sIniFile, "RCON Settings", "RCONPass", $g_sRCONPass)
	IniWrite($g_c_sIniFile, "Wipe by generating new random seed the first Thursday of each Month? yes/no", "MonthlyWipes", $g_sMonthlyWipes)
	IniWrite($g_c_sIniFile, "Use SteamCMD To Update Server? yes/no", "UseSteamCMD", $g_sUseSteamCMD)
	IniWrite($g_c_sIniFile, "Use SteamCMD To Update Server? yes/no", "SteamCmdDir", $g_sSteamCmdDir)
	IniWrite($g_c_sIniFile, "Use SteamCMD To Update Server? yes/no", "ValidateGameFiles", $g_sValidateGame)
	IniWrite($g_c_sIniFile, "Use Remote Restart ?yes/no", "UseRemoteRestart", $g_sUseRemoteRestart)
	IniWrite($g_c_sIniFile, "Use Remote Restart ?yes/no", "RestartPort", $g_sRestartPort)
	IniWrite($g_c_sIniFile, "Use Remote Restart ?yes/no", "RestartUser_Password", $g_sRestartUser_Password)
	IniWrite($g_c_sIniFile, "Hide Passwords in Log? yes/no", "ObfuscatePass", $g_sObfuscatePass)
	IniWrite($g_c_sIniFile, "Check for Update Every X Minutes? yes/no", "CheckForUpdate", $g_sCheckForUpdate)
	IniWrite($g_c_sIniFile, "Update Check Interval in Minutes 05-59", "UpdateInterval", $g_sUpdateInterval)
	IniWrite($g_c_sIniFile, "Install Oxide and Update with Server? yes/no", "UseOxide", $g_sUseOxide)
	IniWrite($g_c_sIniFile, "Restart Server at Set Time? yes/no", "RestartDaily", $g_sRestartDaily)
	IniWrite($g_c_sIniFile, "Daily Restart Hours? 00-23", "RestartHour1", $g_sRestartHour1)
	IniWrite($g_c_sIniFile, "Daily Restart Hours? 00-23", "RestartHour2", $g_sRestartHour2)
	IniWrite($g_c_sIniFile, "Daily Restart Hours? 00-23", "RestartHour3", $g_sRestartHour3)
	IniWrite($g_c_sIniFile, "Daily Restart Hours? 00-23", "RestartHour4", $g_sRestartHour4)
	IniWrite($g_c_sIniFile, "Daily Restart Hours? 00-23", "RestartHour5", $g_sRestartHour5)
	IniWrite($g_c_sIniFile, "Daily Restart Hours? 00-23", "RestartHour6", $g_sRestartHour6)
	IniWrite($g_c_sIniFile, "Daily Restart Minute? 00-59", "RestartMinute", $g_sRestartMinute)
	IniWrite($g_c_sIniFile, "Excessive Memory Amount? in GB", "ExMem", $g_sExMem)
	IniWrite($g_c_sIniFile, "Restart On Excessive Memory Use? yes/no", "ExMemRestart", $g_sExMemRestart)
	IniWrite($g_c_sIniFile, "Rotate X Number of Logs every X Hours? yes/no", "RotateLogs", $g_sRotateLogs)
	IniWrite($g_c_sIniFile, "Rotate X Number of Logs every X Hours? yes/no", "LogQuantity", $g_sLogQuantity)
	IniWrite($g_c_sIniFile, "Rotate X Number of Logs every X Hours? yes/no", "LogHoursBetweenRotate", $g_sLogHoursBetweenRotate)
	IniWrite($g_c_sIniFile, "Use Discord Bot to Send Message Before Restart? yes/no", "UseDiscordBot", $g_sUseDiscordBot)
	IniWrite($g_c_sIniFile, "Use Discord Bot to Send Message Before Restart? yes/no", "DiscordWebHookURL", $g_sDiscordWebHookURLs)
	IniWrite($g_c_sIniFile, "Use Discord Bot to Send Message Before Restart? yes/no", "DiscordBotName", $g_sDiscordBotName)
	IniWrite($g_c_sIniFile, "Use Discord Bot to Send Message Before Restart? yes/no", "DiscordBotUseTTS", $g_sDiscordBotUseTTS)
	IniWrite($g_c_sIniFile, "Use Discord Bot to Send Message Before Restart? yes/no", "DiscordBotAvatarLink", $g_sDiscordBotAvatar)
	IniWrite($g_c_sIniFile, "Use Twitch Bot to Send Message Before Restart? yes/no", "UseTwitchBot", $g_sUseTwitchBot)
	IniWrite($g_c_sIniFile, "Use Twitch Bot to Send Message Before Restart? yes/no", "TwitchNick", $g_sTwitchNick)
	IniWrite($g_c_sIniFile, "Use Twitch Bot to Send Message Before Restart? yes/no", "ChatOAuth", $g_sChatOAuth)
	IniWrite($g_c_sIniFile, "Use Twitch Bot to Send Message Before Restart? yes/no", "TwitchChannels", $g_sTwitchChannels)
	IniWrite($g_c_sIniFile, "Send Message to in Game Players Before Restart? yes/no", "NotifyInGame", $g_sNotifyInGame)
	IniWrite($g_c_sIniFile, "Set the Delay Time Before Restarting when using any Notification Method (minutes)", "TimeBeforeRestart", $g_iDelayShutdownTime)
EndFunc   ;==>UpdateIni
#EndRegion ;**** INI Settings - User Variables ****

Func Gamercide()
	If @exitMethod <> 1 Then
		$Shutdown = MsgBox(4100, "Shut Down?", "Do you wish to shutdown Server " & $g_sServerHostName & "? (PID: " & $g_sRustPID & ")", 60)
		If $Shutdown = 6 Then
			FileWriteLine($g_c_sLogFile, _NowCalc() & " [" & $g_sServerHostName & " (PID: " & $g_sRustPID & ")] Server Shutdown - Intiated by User when closing RustServerUtility Script")
			CloseServer(True)
		EndIf
		MsgBox(4096, "Thanks for using our Application", "Please visit us at https://gamercide.com", 2)
		FileWriteLine($g_c_sLogFile, _NowCalc() & " RustServerUtility Stopped by User")
	Else
		FileWriteLine($g_c_sLogFile, _NowCalc() & " RustServerUtility Stopped")
	EndIf
	If $g_sUseRemoteRestart = "yes" Then
		TCPShutdown()
	EndIf
	Exit
EndFunc   ;==>Gamercide

Func CloseServer($bImmediate = False, $iDelay = 60)
	If WinExists($g_hRusthWnd) Then
		FileWriteLine($g_c_sLogFile, _NowCalc() & " [" & $g_sServerHostName & " (PID: " & $g_sRustPID & ")] Server Window Found - Sending restart command for Clean Shutdown")
		If Not $bImmediate Then
			ControlSend($g_hRusthWnd, "", "", "restart " & $iDelay & "{enter}")
			If $iDelay >= 10 Then
				Local $iSleepTime = ($iDelay * 1000) - 5000
				Sleep($iSleepTime)
			EndIf
			ControlSend($g_hRusthWnd, "", "", 'kickall "" "Server Restarting" {enter}')
			ControlSend($g_hRusthWnd, "", "", "server.save {enter}")
		Else
			ControlSend($g_hRusthWnd, "", "", 'kickall "" "Server Restarting Now" {enter}')
			ControlSend($g_hRusthWnd, "", "", "server.save {enter}")
			ControlSend($g_hRusthWnd, "", "", "quit{enter}")
		EndIf
		WinWaitClose($g_hRusthWnd, "", 60)
		Sleep(2000)
	EndIf
	If ProcessExists($g_sRustPID) Then
		Sleep(8000)
		If ProcessExists($g_sRustPID) Then
			FileWriteLine($g_c_sLogFile, _NowCalc() & " [" & $g_sServerHostName & " (PID: " & $g_sRustPID & ")] Server Did not Shut Down Properly. Killing Process")
			ProcessClose($g_sRustPID)
		EndIf
	EndIf
	If FileExists($g_c_sPIDFile) Then
		FileDelete($g_c_sPIDFile)
	EndIf
	If FileExists($g_c_sHwndFile) Then
		FileDelete($g_c_sHwndFile)
	EndIf
EndFunc   ;==>CloseServer

Func SendInGameMsg($sString)
	ControlSend($g_hRusthWnd, "", "", "say " & $sString & "{enter}")
EndFunc   ;==>SendInGameMsg

Func RotateFile($sFile, $sBackupQty, $bDelOrig = True) ;Pass File to Rotate and Quantity of Files to Keep for backup. Optionally Keep Original.
	Local $hCreateTime = @YEAR & @MON & @MDAY
	For $i = $sBackupQty To 1 Step -1
		If FileExists($sFile & $i) Then
			$hCreateTime = FileGetTime($sFile & $i, 1)
			FileMove($sFile & $i, $sFile & ($i + 1), 1)
			FileSetTime($sFile & ($i + 1), $hCreateTime, 1)
		EndIf
	Next
	If FileExists($sFile & ($sBackupQty + 1)) Then
		FileDelete($sFile & ($sBackupQty + 1))
	EndIf
	If FileExists($sFile) Then
		If $bDelOrig = True Then
			$hCreateTime = FileGetTime($sFile, 1)
			FileMove($sFile, $sFile & "1", 1)
			FileWriteLine($sFile, _NowCalc() & $sFile & " Rotated")
			FileSetTime($sFile & "1", $hCreateTime, 1)
			FileSetTime($sFile, @YEAR & @MON & @MDAY, 1)
		Else
			FileCopy($sFile, $sFile & "1", 1)
		EndIf
	EndIf
EndFunc   ;==>RotateFile

Func ChangeSetting($sINI, $sSection, $sKey, $sValue)
	$bReturn = False
	If FileExists($sINI) Then
		RotateFile($sINI, 4, False)
		IniWrite($sINI, $sSection, $sKey, $sValue)
		$bReturn = True
	Else
		$bReturn = False
	EndIf
	Return $bReturn
EndFunc   ;==>ChangeSetting

Func WipeCheck()
	If @MDAY <= 07 And @WDAY = 5 Then
		Local $iDaySinceWipe = _DateDiff('D', $g_sLastWipeDate, _NowCalc())
		If $iDaySinceWipe >= 27 Then
			$g_sSeed = Random(1, 2147483647, 1)
			$g_sLastWipeDate = _NowCalc()
			IniWrite($g_c_sSeedFile, "Last Wipe Date", "DateofWipe", $g_sLastWipeDate)
			IniWrite($g_c_sSeedFile, "Seed Log", $g_sLastWipeDate & " ServerSeed", $g_sSeed)
			ChangeSetting($g_c_sIniFile, "Server Settings", "WorldSeed", $g_sSeed)
			FileWriteLine($g_c_sLogFile, _NowCalc() & " [" & $g_sServerHostName & "] New Seed Generated. Seed: " & $g_sSeed)
		EndIf
	EndIf
EndFunc   ;==>WipeCheck

#Region ;**** Function to Send Message to Discord ****
Func _Discord_ErrFunc($oError)
	FileWriteLine($g_c_sLogFile, _NowCalc() & " [" & $g_sServerHostName & " (PID: " & $g_sRustPID & ")] Error: 0x" & Hex($oError.number) & " While Sending Discord Bot Message.")
EndFunc   ;==>_Discord_ErrFunc

Func SendDiscordMsg($sHookURLs, $sBotMessage, $sBotName = "", $sBotTTS = False, $sBotAvatar = "")
	Local $oErrorHandler = ObjEvent("AutoIt.Error", "_Discord_ErrFunc")
	Local $sJsonMessage = '{"content" : "' & $sBotMessage & '", "username" : "' & $sBotName & '", "tts" : "' & $sBotTTS & '", "avatar_url" : "' & $sBotAvatar & '"}'
	Local $oHTTPOST = ObjCreate("WinHttp.WinHttpRequest.5.1")
	Local $aHookURLs = StringSplit($sHookURLs, ",")
	For $i = 1 To $aHookURLs[0]
		$oHTTPOST.Open("POST", StringStripWS($aHookURLs[$i], 2) & "?wait=true", False)
		$oHTTPOST.SetRequestHeader("Content-Type", "application/json")
		$oHTTPOST.Send($sJsonMessage)
		Local $oStatusCode = $oHTTPOST.Status
		Local $oResponseText = $oHTTPOST.ResponseText
		FileWriteLine($g_c_sLogFile, _NowCalc() & " [" & $g_sServerHostName & " (PID: " & $g_sRustPID & ")] [Discord Bot] Message Status Code {" & $oStatusCode & "} Message Response " & $oResponseText)
	Next
EndFunc   ;==>SendDiscordMsg
#EndRegion ;**** Function to Send Message to Discord ****

#Region ;**** Post to Twitch Chat Function ****
Opt("TCPTimeout", 500)
Func SendTwitchMsg($sT_Nick, $sT_OAuth, $sT_Channels, $sT_Message)
	Local $aTwitchReturn[4] = [False, False, "", False]
	Local $sTwitchIRC = TCPConnect(TCPNameToIP("irc.chat.twitch.tv"), 6667)
	If @error Then
		TCPCloseSocket($sTwitchIRC)
		Return $aTwitchReturn
	Else
		$aTwitchReturn[0] = True ;Successfully Connected to irc
		TCPSend($sTwitchIRC, "PASS " & StringLower($sT_OAuth) & @CRLF)
		TCPSend($sTwitchIRC, "NICK " & StringLower($sT_Nick) & @CRLF)
		Local $sTwitchReceive = ""
		Local $iTimer1 = TimerInit()
		While TimerDiff($iTimer1) < 1000
			$sTwitchReceive &= TCPRecv($sTwitchIRC, 1)
			If @error Then ExitLoop
		WEnd
		Local $aTwitchReceiveLines = StringSplit($sTwitchReceive, @CRLF, 1)
		$aTwitchReturn[2] = $aTwitchReceiveLines[1] ;Status Line. Accepted or Not
		If StringRegExp($aTwitchReceiveLines[$aTwitchReceiveLines[0] - 1], "(?i):tmi.twitch.tv 376 " & $sT_Nick & " :>") Then
			$aTwitchReturn[1] = True ;Username and OAuth was accepted. Ready for PRIVMSG
			Local $aTwitchChannels = StringSplit($sT_Channels, ",")
			For $i = 1 To $aTwitchChannels[0]
				TCPSend($sTwitchIRC, "PRIVMSG #" & StringLower($aTwitchChannels[$i]) & " :" & $sT_Message & @CRLF)
				If @error Then
					TCPCloseSocket($sTwitchIRC)
					$aTwitchReturn[3] = False ;Check that all channels succeeded or none
					Return $aTwitchReturn
					ExitLoop
				Else
					$aTwitchReturn[3] = True ;Check that all channels succeeded or none
					If $aTwitchChannels[0] > 17 Then ;This is to make sure we don't break the rate limit
						Sleep(1600)
					Else
						Sleep(100)
					EndIf
				EndIf
			Next
			TCPSend($sTwitchIRC, "QUIT")
			TCPCloseSocket($sTwitchIRC)
		Else
			Return $aTwitchReturn
		EndIf
	EndIf
	Return $aTwitchReturn
EndFunc   ;==>SendTwitchMsg

Func TwitchMsgLog($sT_Msg)
	Local $aTwitchIRC = SendTwitchMsg($g_sTwitchNick, $g_sChatOAuth, $g_sTwitchChannels, $sT_Msg)
	If $aTwitchIRC[0] Then
		FileWriteLine($g_c_sLogFile, _NowCalc() & " [" & $g_sServerHostName & " (PID: " & $g_sRustPID & ")] [Twitch Bot] Successfully Connected to Twitch IRC")
		If $aTwitchIRC[1] Then
			FileWriteLine($g_c_sLogFile, _NowCalc() & " [" & $g_sServerHostName & " (PID: " & $g_sRustPID & ")] [Twitch Bot] Username and OAuth Accepted. [" & $aTwitchIRC[2] & "]")
			If $aTwitchIRC[3] Then
				FileWriteLine($g_c_sLogFile, _NowCalc() & " [" & $g_sServerHostName & " (PID: " & $g_sRustPID & ")] [Twitch Bot] Successfully sent ( " & $sT_Msg & " ) to all Channels")
			Else
				FileWriteLine($g_c_sLogFile, _NowCalc() & " [" & $g_sServerHostName & " (PID: " & $g_sRustPID & ")] [Twitch Bot] ERROR | Failed sending message ( " & $sT_Msg & " ) to one or more channels")
			EndIf
		Else
			FileWriteLine($g_c_sLogFile, _NowCalc() & " [" & $g_sServerHostName & " (PID: " & $g_sRustPID & ")] [Twitch Bot] ERROR | Username and OAuth Denied [" & $aTwitchIRC[2] & "]")
		EndIf
	Else
		FileWriteLine($g_c_sLogFile, _NowCalc() & " [" & $g_sServerHostName & " (PID: " & $g_sRustPID & ")] [Twitch Bot] ERROR | Could not connect to Twitch IRC. Is this URL or port blocked? [irc.chat.twitch.tv:6667]")
	EndIf
EndFunc   ;==>TwitchMsgLog
#EndRegion ;**** Post to Twitch Chat Function ****

#Region ;**** Functions to Check for Update ****
Func GetLatestVersion($sCmdDir)
	Local $aReturn[2] = [False, ""]
	If FileExists($sCmdDir & "\appcache") Then
		DirRemove($sCmdDir & "\appcache", 1)
	EndIf
	RunWait('"' & @ComSpec & '" /c ' & $sCmdDir & '\steamcmd.exe +login anonymous +app_info_update 1 +app_info_print 258550 +app_info_print 258550 +exit > app_info.tmp', $sCmdDir, @SW_HIDE)
	Local Const $sFilePath = $sCmdDir & "\app_info.tmp"
	Local $hFileOpen = FileOpen($sFilePath, 0)
	If $hFileOpen = -1 Then
		$aReturn[0] = False
	Else
		Local $sFileRead = FileRead($hFileOpen)
		Local $aAppInfo = StringSplit($sFileRead, '"branches"', 1)

		If UBound($aAppInfo) >= 3 Then
			$aAppInfo = StringSplit($aAppInfo[2], "AppID", 1)
		EndIf
		If UBound($aAppInfo) >= 2 Then
			$aAppInfo = StringSplit($aAppInfo[1], "}", 1)
		EndIf
		If UBound($aAppInfo) >= 2 Then
			$aAppInfo = StringSplit($aAppInfo[1], '"', 1)
		EndIf
		If UBound($aAppInfo) >= 7 Then
			$aReturn[0] = True
			$aReturn[1] = $aAppInfo[6]
		EndIf
		FileClose($hFileOpen)
		If FileExists($sFilePath) Then
			FileDelete($sFilePath)
		EndIf
	EndIf
	Return $aReturn
EndFunc   ;==>GetLatestVersion

Func GetInstalledVersion($sGameDir)
	Local $aReturn[2] = [False, ""]
	Local Const $sFilePath = $sGameDir & "\steamapps\appmanifest_258550.acf"
	Local $hFileOpen = FileOpen($sFilePath, 0)
	If $hFileOpen = -1 Then
		$aReturn[0] = False
	Else
		Local $sFileRead = FileRead($hFileOpen)
		Local $aAppInfo = StringSplit($sFileRead, '"buildid"', 1)

		If UBound($aAppInfo) >= 3 Then
			$aAppInfo = StringSplit($aAppInfo[2], '"buildid"', 1)
		EndIf
		If UBound($aAppInfo) >= 2 Then
			$aAppInfo = StringSplit($aAppInfo[1], '"LastOwner"', 1)
		EndIf
		If UBound($aAppInfo) >= 2 Then
			$aAppInfo = StringSplit($aAppInfo[1], '"', 1)
		EndIf
		If UBound($aAppInfo) >= 2 Then
			$aReturn[0] = True
			$aReturn[1] = $aAppInfo[2]
		EndIf

		If FileExists($sFilePath) Then
			FileClose($hFileOpen)
		EndIf
	EndIf
	Return $aReturn
EndFunc   ;==>GetInstalledVersion

Func UpdateCheck()
	If FileExists($g_sSteamCmdDir & "\app_info.tmp") Then
		FileWriteLine($g_c_sLogFile, _NowCalc() & " [" & $g_sServerHostName & " (PID: " & $g_sRustPID & ")] Delaying Update Check for 1 minute. | Found Existing " & $g_sSteamCmdDir & "\app_info.tmp")
		Sleep(60000)
		If FileExists($g_sSteamCmdDir & "\app_info.tmp") Then
			FileDelete($g_sSteamCmdDir & "\app_info.tmp")
			FileWriteLine($g_c_sLogFile, _NowCalc() & " [" & $g_sServerHostName & " (PID: " & $g_sRustPID & ")] Deleted " & $g_sSteamCmdDir & "\app_info.tmp")
		EndIf
	EndIf

	FileWriteLine($g_c_sLogFile, _NowCalc() & " [" & $g_sServerHostName & " (PID: " & $g_sRustPID & ")] Update Check Starting.")
	Local $bUpdateRequired = False
	Local $aLatestVersion = GetLatestVersion($g_sSteamCmdDir)
	Local $aInstalledVersion = GetInstalledVersion($g_sServerDir)

	If ($aLatestVersion[0] And $aInstalledVersion[0]) Then
		If StringCompare($aLatestVersion[1], $aInstalledVersion[1]) = 0 Then
			FileWriteLine($g_c_sLogFile, _NowCalc() & " [" & $g_sServerHostName & " (PID: " & $g_sRustPID & ")] Server is Up to Date. Version: " & $aInstalledVersion[1])
		Else
			FileWriteLine($g_c_sLogFile, _NowCalc() & " [" & $g_sServerHostName & " (PID: " & $g_sRustPID & ")] Server is Out of Date! Installed Version: " & $aInstalledVersion[1] & " Latest Version: " & $aLatestVersion[1])
			$bUpdateRequired = True
		EndIf
	ElseIf Not $aLatestVersion[0] And Not $aInstalledVersion[0] Then
		FileWriteLine($g_c_sLogFile, _NowCalc() & " [" & $g_sServerHostName & " (PID: " & $g_sRustPID & ")] Something went wrong retrieving Latest Version")
		FileWriteLine($g_c_sLogFile, _NowCalc() & " [" & $g_sServerHostName & " (PID: " & $g_sRustPID & ")] Something went wrong retrieving Installed Version")
	ElseIf Not $aInstalledVersion[0] Then
		FileWriteLine($g_c_sLogFile, _NowCalc() & " [" & $g_sServerHostName & " (PID: " & $g_sRustPID & ")] Something went wrong retrieving Installed Version")
	ElseIf Not $aLatestVersion[0] Then
		FileWriteLine($g_c_sLogFile, _NowCalc() & " [" & $g_sServerHostName & " (PID: " & $g_sRustPID & ")] Something went wrong retrieving Latest Version")
	EndIf
	Return $bUpdateRequired
EndFunc   ;==>UpdateCheck
#EndRegion ;**** Functions to Check for Update ****

#Region ;**** Function to Download Oxide ****
Func DownloadOxide()
	Local Const $g_c_sTempDir = $g_sServerDir & "\tmp\"
	If FileExists($g_c_sTempDir) Then
		DirRemove($g_c_sTempDir, 1)
	EndIf
	DirCreate($g_sServerDir & "\tmp")
	InetGet("https://dl.bintray.com/oxidemod/builds/Oxide-Rust.zip", $g_c_sTempDir & "Oxide-Rust.zip", 0)
	Local Const $sFilePath = $g_c_sTempDir & "Oxide-Rust.zip"
	If FileExists($sFilePath) Then
		Local $hExtractFile = _ExtractZip($g_c_sTempDir & "Oxide-Rust.zip", "", "RustDedicated_Data", $g_c_sTempDir)
		If $hExtractFile Then
			FileWriteLine($g_c_sLogFile, _NowCalc() & " Latest Oxide Verion Downloaded.")
			If FileExists($g_c_sTempDir & "RustDedicated_Data") Then
				DirCopy($g_c_sTempDir & "RustDedicated_Data", $g_sServerDir & "\RustDedicated_Data", 1)
				FileWriteLine($g_c_sLogFile, _NowCalc() & " Oxide Updated")
			Else
				FileWriteLine($g_c_sLogFile, _NowCalc() & " Something went wrong Moving Oxide Folder.")
			EndIf
		Else
			FileWriteLine($g_c_sLogFile, _NowCalc() & " Something went wrong Extracting Oxide Zip. Error Code: " & @error)
		EndIf
		DirRemove($g_c_sTempDir, 1)
	Else
		FileWriteLine($g_c_sLogFile, _NowCalc() & " Something Went Wrong Downloading Oxide.")
	EndIf
EndFunc   ;==>DownloadOxide
#EndRegion ;**** Function to Download Oxide ****

#Region ;**** Functions for Multiple Passwords and Hiding Password ****
Func PassCheck($sPass, $sPassString)
	Local $aPassReturn[3] = [False, "", ""]
	Local $aPasswords = StringSplit($sPassString, ",")
	For $i = 1 To $aPasswords[0]
		If (StringCompare($sPass, $aPasswords[$i], 1) = 0) Then
			Local $aUserPass = StringSplit($aPasswords[$i], "_")
			If $aUserPass[0] > 1 Then
				$aPassReturn[0] = True
				$aPassReturn[1] = $aUserPass[1]
				$aPassReturn[2] = $aUserPass[2]
			Else
				$aPassReturn[0] = True
				$aPassReturn[1] = "Anonymous"
				$aPassReturn[2] = $aUserPass[1]
			EndIf
			ExitLoop
		EndIf
	Next
	Return $aPassReturn
EndFunc   ;==>PassCheck

Func ObfPass($sObfPassString)
	Local $sObfPass = ""
	For $i = 1 To (StringLen($sObfPassString) - 3)
		If $i <> 4 Then
			$sObfPass = $sObfPass & "*"
		Else
			$sObfPass = $sObfPass & StringMid($sObfPassString, 4, 4)
		EndIf
	Next
	Return $sObfPass
EndFunc   ;==>ObfPass
#EndRegion ;**** Functions for Multiple Passwords and Hiding Password ****

#Region ;**** Function to get IP from Restart Client ****
Func _TCP_Server_ClientIP($hSocket)
	Local $pSocketAddress, $aReturn
	$pSocketAddress = DllStructCreate("short;ushort;uint;char[8]")
	$aReturn = DllCall("ws2_32.dll", "int", "getpeername", "int", $hSocket, "ptr", DllStructGetPtr($pSocketAddress), "int*", DllStructGetSize($pSocketAddress))
	If @error Or $aReturn[0] <> 0 Then Return $hSocket
	$aReturn = DllCall("ws2_32.dll", "str", "inet_ntoa", "int", DllStructGetData($pSocketAddress, 3))
	If @error Then Return $hSocket
	$pSocketAddress = 0
	Return $aReturn[0]
EndFunc   ;==>_TCP_Server_ClientIP
#EndRegion ;**** Function to get IP from Restart Client ****

#Region ;**** Startup Checks. Initial Log, Read INI, Check for Correct Paths, Check Remote Restart is bound to port. ****
OnAutoItExitRegister("Gamercide")
FileWriteLine($g_c_sLogFile, _NowCalc() & " RustServerUtility Script v1.0.0-rc.3 Started")
ReadUini()

If $g_sUseSteamCMD = "yes" Then
	Local $sFileExists = FileExists($g_sSteamCmdDir & "\steamcmd.exe")
	If $sFileExists = 0 Then
		DirCreate($g_sSteamCmdDir) ; to extract to
		InetGet("https://steamcdn-a.akamaihd.net/client/installer/steamcmd.zip", $g_sSteamCmdDir & "\steamcmd.zip", 0)
		_ExtractZip($g_sSteamCmdDir & "\steamcmd.zip", "", "steamcmd.exe", $g_sSteamCmdDir)
		FileDelete($g_sSteamCmdDir & "\steamcmd.zip")
		FileWriteLine($g_c_sLogFile, _NowCalc() & " Running SteamCMD with validate. [steamcmd.exe +@ShutdownOnFailedCommand 1 +@NoPromptForPassword 1 +login anonymous +force_install_dir " & $g_sServerDir & " +app_update 258550 validate +quit]")
		RunWait("" & $g_sSteamCmdDir & "\steamcmd.exe +quit")
		If Not FileExists($g_sSteamCmdDir & "\steamcmd.exe") Then
			MsgBox(0x0, "SteamCMD Not Found", "Could not find steamcmd.exe at " & $g_sSteamCmdDir)
			Exit
		EndIf
	EndIf
	Local $sManifestExists = FileExists($g_sSteamCmdDir & "\steamapps\appmanifest_258550.acf")
	If $sManifestExists = 1 Then
		Local $manifestFound = MsgBox(4100, "Warning", "Install manifest found at " & $g_sSteamCmdDir & "\steamapps\appmanifest_258550.acf" & @CRLF & @CRLF & "Suggest moving file to " & _
				$g_sServerDir & "\steamapps\appmanifest_258550.acf before running SteamCMD" & @CRLF & @CRLF & "Would you like to Exit Now?", 20)
		If $manifestFound = 6 Then
			Exit
		EndIf
	EndIf
Else
	Local $cFileExists = FileExists($g_sServerDir & "\RustDedicated.exe")
	If $cFileExists = 0 Then
		MsgBox(0x0, "Rust Server Not Found", "Could not find RustDedicated.exe at " & $g_sServerDir)
		Exit
	EndIf
EndIf


If $g_sUseRemoteRestart = "yes" Then
	; Start The TCP Services
	TCPStartup()
	Local $MainSocket = TCPListen($g_sServerIP, $g_sRestartPort, 100)
	If $MainSocket = -1 Then
		MsgBox(0x0, "TCP Error", "Could not bind to [" & $g_sServerIP & "] Check server IP or disable Remote Restart in INI")
		FileWriteLine($g_c_sLogFile, _NowCalc() & " Remote Restart Enabled. Could not bind to " & $g_sServerIP & ":" & $g_sRestartPort)
		Exit
	Else
		FileWriteLine($g_c_sLogFile, _NowCalc() & " Remote Restart Enabled. Listening for Restart Request at " & $g_sServerIP & ":" & $g_sRestartPort)
	EndIf
EndIf
#EndRegion ;**** Startup Checks. Initial Log, Read INI, Check for Correct Paths, Check Remote Restart is bound to port. ****

While True ;**** Loop Until Closed ****
	#Region ;**** Listen for Remote Restart Request ****
	If $g_sUseRemoteRestart = "yes" Then
		Local $ConnectedSocket = TCPAccept($MainSocket)
		If $ConnectedSocket >= 0 Then
			$Count = 0
			While $Count < 30
				Local $sRECV = TCPRecv($ConnectedSocket, 512)
				Local $aPassCompare = PassCheck($sRECV, $g_sRestartUser_Password)
				If $g_sObfuscatePass = "yes" Then
					$aPassCompare[2] = ObfPass($aPassCompare[2])
				EndIf
				If $aPassCompare[0] Then
					If ProcessExists($g_sRustPID) Then
						Local $IP = _TCP_Server_ClientIP($ConnectedSocket)
						Local $MEM = ProcessGetStats($g_sRustPID, 0)
						FileWriteLine($g_c_sLogFile, _NowCalc() & " [" & $g_sServerHostName & " (PID: " & $g_sRustPID & ")] [Work Memory:" & $MEM[0] & " | Peak Memory:" & $MEM[1] & "] Restart Requested by Remote Host: " & $IP & " | User: " & $aPassCompare[1] & " | Pass: " & $aPassCompare[2])
						Local $sRemoteRestartMessage = $g_sServerHostName & ": Remote Restart Requested by " & $aPassCompare[1] & ". Restarting Server in 20 Seconds"
						If $g_sUseDiscordBot = "yes" Then
							SendDiscordMsg($g_sDiscordWebHookURLs, $sRemoteRestartMessage, $g_sDiscordBotName, $g_sDiscordBotUseTTS, $g_sDiscordBotAvatar)
						EndIf
						If $g_sUseTwitchBot = "yes" Then
							TwitchMsgLog($sRemoteRestartMessage)
						EndIf
						If $g_sNotifyInGame = "yes" Then
							SendInGameMsg($sRemoteRestartMessage)
						EndIf
						CloseServer(False, 20)
						Sleep(10000)
						ExitLoop
					EndIf
				Else
					Local $IP = _TCP_Server_ClientIP($ConnectedSocket)
					FileWriteLine($g_c_sLogFile, _NowCalc() & " [" & $g_sServerHostName & " (PID: " & $g_sRustPID & ")] Restart ATTEMPT by Remote Host: " & $IP & " | Unknown Restart Code: " & $sRECV)
					ExitLoop
				EndIf
				$Count += 1
				Sleep(1000)
			WEnd
			If $ConnectedSocket <> -1 Then TCPCloseSocket($ConnectedSocket)
		EndIf
	EndIf
	#EndRegion ;**** Listen for Remote Restart Request ****

	#Region ;**** Keep Server Alive Check. ****
	If Not ProcessExists($g_sRustPID) Then
		$g_iBeginDelayedShutdown = 0
		If $g_sUseSteamCMD = "yes" Then
			If $g_sValidateGame = "yes" Then
				FileWriteLine($g_c_sLogFile, _NowCalc() & " Running SteamCMD with validate. [steamcmd.exe +@ShutdownOnFailedCommand 1 +@NoPromptForPassword 1 +login anonymous +force_install_dir " & $g_sServerDir & " +app_update 258550 validate +quit]")
				RunWait("" & $g_sSteamCmdDir & "\steamcmd.exe +@ShutdownOnFailedCommand 1 +@NoPromptForPassword 1 +login anonymous +force_install_dir " & $g_sServerDir & " +app_update 258550 validate +quit")
			Else
				FileWriteLine($g_c_sLogFile, _NowCalc() & " Running SteamCMD without validate. [steamcmd.exe +@ShutdownOnFailedCommand 1 +@NoPromptForPassword 1 +login anonymous +force_install_dir " & $g_sServerDir & " +app_update 258550 +quit]")
				RunWait("" & $g_sSteamCmdDir & "\steamcmd.exe +@ShutdownOnFailedCommand 1 +@NoPromptForPassword 1 +login anonymous +force_install_dir " & $g_sServerDir & " +app_update 258550 +quit")
			EndIf
			If $g_sUseOxide = "yes" Then
				DownloadOxide()
			EndIf
			If $g_sMonthlyWipes = "yes" Then
				WipeCheck()
			EndIf
		EndIf
		$g_sRustPID = Run("" & $g_sServerDir & "\" & $g_c_sServerEXE & " -batchmode +server.identity " & $g_sServerIdentity & " +server.ip " & $g_sServerIP & " +server.port " & $g_sServerPort & " +server.hostname """ & $g_sServerHostName & _
				""" +server.seed " & $g_sSeed & " +server.maxplayers " & $g_sMaxPlayers & " +server.worldsize " & $g_sWorldSize & " +server.saveinterval " & $g_sSaveInterval & " +server.tickrate " & $g_sTickRate & " +server.headerimage """ & $g_sServerHeaderImage & """ +server.url """ & $g_sServerURL & _
				""" +server.description """ & $g_sServerDescription & """ +rcon.ip " & $g_sRCONIP & " +rcon.port " & $g_sRCONPort & " +rcon.password """ & $g_sRCONPass & """ -logfile """ & $g_sServerDir & "\RustLogs\" & $g_sServerIdentity & "_" & @YEAR & "_" & @MON & "_" & @MDAY & "_" & @HOUR & @MIN & ".log""", $g_sServerDir)

		If $g_sObfuscatePass = "yes" Then
			$g_sRCONp = ObfPass($g_sRCONPass)
		Else
			$g_sRCONp = $g_sRCONPass
		EndIf
		FileWriteLine($g_c_sLogFile, _NowCalc() & " [" & $g_sServerHostName & " (PID: " & $g_sRustPID & ")] Started [" & $g_c_sServerEXE & " -batchmode +server.identity " & $g_sServerIdentity & " +server.ip " & $g_sServerIP & " +server.port " & $g_sServerPort & " +server.hostname """ & $g_sServerHostName & _
				""" +server.seed " & $g_sSeed & " +server.maxplayers " & $g_sMaxPlayers & " +server.worldsize " & $g_sWorldSize & " +server.saveinterval " & $g_sSaveInterval & " +server.tickrate " & $g_sTickRate & " +server.headerimage """ & $g_sServerHeaderImage & """ +server.url """ & $g_sServerURL & _
				""" +server.description """ & $g_sServerDescription & """ +rcon.ip " & $g_sRCONIP & " +rcon.port " & $g_sRCONPort & " +rcon.password """ & $g_sRCONp & """ -logfile """ & $g_sServerDir & "\RustLogs\" & $g_sServerIdentity & "_" & @YEAR & "_" & @MON & "_" & @MDAY & "_" & @HOUR & @MIN & ".log]""")

		If @error Or Not $g_sRustPID Then
			If Not IsDeclared("iMsgBoxAnswer") Then Local $iMsgBoxAnswer
			$iMsgBoxAnswer = MsgBox(262405, "Server Failed to Start", "The server tried to start, but it failed. Try again? This will automatically close in 60 seconds and try to start again.", 60)
			Select
				Case $iMsgBoxAnswer = 4 ;Retry
					FileWriteLine($g_c_sLogFile, _NowCalc() & " [" & $g_sServerHostName & " (PID: " & $g_sRustPID & ")] Server Failed to Start. User Initiated a Restart Attempt.")
				Case $iMsgBoxAnswer = 2 ;Cancel
					FileWriteLine($g_c_sLogFile, _NowCalc() & " [" & $g_sServerHostName & " (PID: " & $g_sRustPID & ")] Server Failed to Start - RustServerUtility Shutdown - Intiated by User")
					Exit
				Case $iMsgBoxAnswer = -1 ;Timeout
					FileWriteLine($g_c_sLogFile, _NowCalc() & " [" & $g_sServerHostName & " (PID: " & $g_sRustPID & ")] Server Failed to Start. Script Initiated Restart Attempt after 60 seconds of no User Input.")
			EndSelect
		EndIf
		$g_hRusthWnd = WinGetHandle(WinWait("" & $g_sServerDir & "", "", 70))
		If FileExists($g_c_sPIDFile) Then
			FileDelete($g_c_sPIDFile)
		EndIf
		If FileExists($g_c_sHwndFile) Then
			FileDelete($g_c_sHwndFile)
		EndIf
		FileWrite($g_c_sPIDFile, $g_sRustPID)
		FileWrite($g_c_sHwndFile, String($g_hRusthWnd))
		FileSetAttrib($g_c_sPIDFile, "+HT")
		FileSetAttrib($g_c_sHwndFile, "+HT")
		FileWriteLine($g_c_sLogFile, _NowCalc() & " [" & $g_sServerHostName & " (PID: " & $g_sRustPID & ")] Window Handle Found: " & $g_hRusthWnd)
	ElseIf ((_DateDiff('n', $g_sTimeCheck1, _NowCalc())) >= 5) Then
		Local $MEM = ProcessGetStats($g_sRustPID, 0)
		Local $MaxMem = $g_sExMem * 1000000000
		If $MEM[0] > $MaxMem And $g_sExMemRestart = "no" Then
			FileWriteLine($g_c_sLogFile, _NowCalc() & " [" & $g_sServerHostName & " (PID: " & $g_sRustPID & ")] Work Memory:" & $MEM[0] & " Peak Memory:" & $MEM[1])
		ElseIf $MEM[0] > $MaxMem And $g_sExMemRestart = "yes" Then
			FileWriteLine($g_c_sLogFile, _NowCalc() & " [" & $g_sServerHostName & " (PID: " & $g_sRustPID & ")] Work Memory:" & $MEM[0] & " Peak Memory:" & $MEM[1] & " Excessive Memory Use - Restart Requested by RustServerUtility Script")
			If ($g_sUseDiscordBot = "yes") Or ($g_sUseTwitchBot = "yes") Or ($g_sNotifyInGame = "yes") Then
				$g_iBeginDelayedShutdown = 1
			Else
				CloseServer(True)
			EndIf
		EndIf
		$g_sTimeCheck1 = _NowCalc()
	EndIf
	#EndRegion ;**** Keep Server Alive Check. ****

	#Region ;**** Restart Server Every X Hours ****
	If ($g_sRestartDaily = "yes" And $g_iBeginDelayedShutdown = 0 And (@HOUR = $g_sRestartHour1 Or @HOUR = $g_sRestartHour2 Or @HOUR = $g_sRestartHour3 Or @HOUR = $g_sRestartHour4 Or @HOUR = $g_sRestartHour5 Or @HOUR = $g_sRestartHour6) And @MIN = $g_sRestartMinute And ((_DateDiff('n', $g_sTimeCheck2, _NowCalc())) >= 1)) Then
		If $g_sMonthlyWipes = "yes" And @MDAY <= 07 And @WDAY = 5 Then
			FileWriteLine($g_c_sLogFile, _NowCalc() & " [" & $g_sServerHostName & " (PID: " & $g_sRustPID & ")] Daily Restarts Skipped on The First Thursday of the month to prevent double wipe")
		Else
			If ProcessExists($g_sRustPID) Then
				Local $MEM = ProcessGetStats($g_sRustPID, 0)
				FileWriteLine($g_c_sLogFile, _NowCalc() & " [" & $g_sServerHostName & " (PID: " & $g_sRustPID & ")] Work Memory:" & $MEM[0] & " Peak Memory:" & $MEM[1] & " - Daily Restart Requested by RustServerUtility Script")
				If ($g_sUseDiscordBot = "yes") Or ($g_sUseTwitchBot = "yes") Or ($g_sNotifyInGame = "yes") Then
					$g_iBeginDelayedShutdown = 1
					$g_sTimeCheck0 = _NowCalc
				Else
					CloseServer(True)
				EndIf
			EndIf
		EndIf
		$g_sTimeCheck2 = _NowCalc()
	EndIf
	#EndRegion ;**** Restart Server Every X Hours ****

	#Region ;**** Check for Update every X Minutes ****
	If ($g_sCheckForUpdate = "yes") And ((_DateDiff('n', $g_sTimeCheck0, _NowCalc())) >= $g_sUpdateInterval) And ($g_iBeginDelayedShutdown = 0) Then
		Local $bRestart = UpdateCheck()
		If $bRestart And (($g_sUseDiscordBot = "yes") Or ($g_sUseTwitchBot = "yes") Or ($g_sNotifyInGame = "yes")) Then
			$g_iBeginDelayedShutdown = 1
		ElseIf $bRestart Then
			CloseServer(True)
		EndIf
		$g_sTimeCheck0 = _NowCalc()
	EndIf
	#EndRegion ;**** Check for Update every X Minutes ****

	#Region ;**** Announce to Twitch or Discord or Both ****
	If ($g_sUseDiscordBot = "yes") Or ($g_sUseTwitchBot = "yes") Or ($g_sNotifyInGame = "yes") Then
		If $g_iBeginDelayedShutdown = 1 Then
			FileWriteLine($g_c_sLogFile, _NowCalc() & " [" & $g_sServerHostName & " (PID: " & $g_sRustPID & ")] Notification in Use. Delaying Shutdown for " & $g_iDelayShutdownTime & " minutes. Notifying Channel")
			Local $sShutdownMessage = $g_sServerHostName & " Restarting in " & $g_iDelayShutdownTime & " minutes"
			If $g_sUseDiscordBot = "yes" Then
				SendDiscordMsg($g_sDiscordWebHookURLs, $sShutdownMessage, $g_sDiscordBotName, $g_sDiscordBotUseTTS, $g_sDiscordBotAvatar)
			EndIf
			If $g_sUseTwitchBot = "yes" Then
				TwitchMsgLog($sShutdownMessage)
			EndIf
			If $g_sNotifyInGame = "yes" Then
				SendInGameMsg($sShutdownMessage)
			EndIf
			$g_iBeginDelayedShutdown = 2
			$g_sTimeCheck0 = _NowCalc()
		ElseIf ($g_iBeginDelayedShutdown >= 2 And ((_DateDiff('n', $g_sTimeCheck0, _NowCalc())) >= $g_iDelayShutdownTime - 1)) Then
			$g_iBeginDelayedShutdown = 0
			$g_sTimeCheck0 = _NowCalc()
			CloseServer()
		ElseIf $g_iBeginDelayedShutdown = 2 And ((_DateDiff('n', $g_sTimeCheck0, _NowCalc())) >= ($g_iDelayShutdownTime - 2)) Then
			Local $sShutdownMessage = $g_sServerHostName & " Restarting in 2 minutes. Final Warning"
			If $g_sUseDiscordBot = "yes" Then
				SendDiscordMsg($g_sDiscordWebHookURLs, $sShutdownMessage, $g_sDiscordBotName, $g_sDiscordBotUseTTS, $g_sDiscordBotAvatar)
			EndIf
			If $g_sUseTwitchBot = "yes" Then
				TwitchMsgLog($sShutdownMessage)
			EndIf
			If $g_sNotifyInGame = "yes" Then
				SendInGameMsg($sShutdownMessage)
			EndIf
			$g_iBeginDelayedShutdown = 3
		EndIf
	Else
		$g_iBeginDelayedShutdown = 0
	EndIf
	#EndRegion ;**** Announce to Twitch or Discord or Both ****

	#Region ;**** Rotate Logs ****
	If ($g_sRotateLogs = "yes") And ((_DateDiff('h', $g_sTimeCheck4, _NowCalc())) >= 1) Then
		If Not FileExists($g_c_sLogFile) Then
			FileWriteLine($g_c_sLogFile, $g_sTimeCheck4 & " Log File Created")
			FileSetTime($g_c_sLogFile, @YEAR & @MON & @MDAY, 1)
		EndIf
		Local $g_c_sLogFileTime = FileGetTime($g_c_sLogFile, 1)
		Local $logTimeSinceCreation = _DateDiff('h', $g_c_sLogFileTime[0] & "/" & $g_c_sLogFileTime[1] & "/" & $g_c_sLogFileTime[2] & " " & $g_c_sLogFileTime[3] & ":" & $g_c_sLogFileTime[4] & ":" & $g_c_sLogFileTime[5], _NowCalc())
		If $logTimeSinceCreation >= $g_sLogHoursBetweenRotate Then
			RotateFile($g_c_sLogFile, $g_sLogQuantity)
		EndIf
		$g_sTimeCheck4 = _NowCalc()
	EndIf
	#EndRegion ;**** Rotate Logs ****
	Sleep(1000)
WEnd
