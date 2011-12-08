#include FcnLib.ahk
#include SendEmailSimpleLib.ahk
#include gitExempt/Lynx-Passwords.ahk

ExitApp ;this is a lib

ConfigureODBC(version)
{
   if (version == "32")
      Run, C:\Windows\system32\
   else if (version == "64")
      Run, C:\Windows\SysWOW64\

   SleepSeconds(2)
   SleepSend("odbcad32{ENTER}")

   ForceWinFocus("ODBC Data Source Administrator")
   SleepClick(106,  41)
   SleepClick(401,  94)
   ForceWinFocus("Create New Data Source")
   SleepSend("{DOWN 50}")
   SleepSend("{UP}")
   SleepClick(330,  319)
   ForceWinFocus("Create a New Data Source to SQL Server")
   SleepSend("!m")
   SleepSend("LynxSQL")
   SleepSend("!d")
   SleepSend("Lynx")
   SleepSend("!s")
   SleepSend("(local)")
   SleepSend("!n")
   WinWaitActive, , verify the authenticity, 10
   SleepSend("!n")
   WinWaitActive, , default database, 10
   SleepSend("!d")
   SleepSend("{TAB}")
   SleepSend("Lynx")
   SleepSend("!n")
   WinWaitActive, , Change the language, 10
   ;if (version == "32")
      ;SleepClick(292, 363)
   ;else if (version == "64")
   SleepClick(292, 327)
   WinWaitActive, , &Test Data Source, 10
   SleepSend("!t")
   SetTitleMatchMode, Slow
   WinWaitActive, , TESTS COMPLETED SUCCESSFULLY
   SetTitleMatchMode, Fast
   SleepClick(179, 353)

   WinWaitActive, , &Test Data Source, 10
   SleepClick(258, 353)
   ForceWinFocus("ODBC Data Source Administrator")
   SleepClick(170, 353)
   SleepSeconds(1)
}

SleepSend(text)
{
   ShortSleep()
   Sleep, 3000
   Send, %text%
}

SleepClick(xCoord, yCoord, options="Left Mouse")
{
   ShortSleep()
   Sleep, 3000
   Click(xCoord, yCoord, options)
}

RestartService(serviceName)
{
   ;NOTE I could use the sc command, but that wouldn't wait for the service to start successfully
   ;the NET command is basically a RunWait for services
   Sleep, 100
   CmdRet_RunReturn("net stop " . serviceName)
   Sleep, 100
   CmdRet_RunReturn("net start " . serviceName)
   Sleep, 100
}

AllServicesAre(status)
{
   ;usage: stopped or running or started
   if InStr(status, "STOPPED")
      status=STOPPED
   else if InStr(status, "STARTED") OR InStr(status, "RUNNING")
      status=RUNNING
   else
      fatalErrord("", "USAGE: AllServicesAre(status) where status can be started, stopped or running")

   services:="apache2.2,LynxApp1,LynxTCPService,LynxMessageServer,LynxMessageServer2,LynxMessageServer3"
   Loop, parse, services, CSV
   {
      serviceName:=A_LoopField
      ret := CmdRet_RunReturn("sc query " . serviceName)
      Sleep, 100
      if NOT InStr(ret, status)
      {
         ;debug("not stopped: ", serviceName)
         return false
      }
   }
   return true
}

StopAllLynxServices()
{
   RemoveAll()
   CmdRet_RunReturn("net stop apache2.2")
   TCP:="LynxTCPService.exe"
   ProcessClose(TCP)
   ProcessClose(TCP)
   ProcessClose(TCP)
   Sleep, 500
   if ProcessExist(TCP)
      lynx_error("LynxTCP service didn't seem to close")
}

BannerDotPlx()
{
   ret := CmdRet_Perl("banner.plx")
   lynx_log("banner.plx returned: " . ret)
   if NOT InStr(ret, "Location: /banner") ;/banner.gif")
      lynx_error("the banner.plx file did not run correctly, instead it returned:" . ret)
}

;TODO run checkdb again (automated), pipe to log
CheckDb()
{
   ret := CmdRet_Perl("checkdb.plx")
   len := strlen(ret)
   msg=Ran checkdb and the strlen of the checkdb was %len%
   FileAppendLine(msg, GetPath("logfile")) ;log abbreviated message
   FileAppendLine(ret, GetPath("checkdb-logfile")) ;log full message to separate log
}

RemoveAll()
{
   ret := CmdRet_Perl("start-MSG-service.pl removeall")
   len := strlen(ret)
   msg=Removed all services and the strlen of the removeall was %len%
   FileAppendLine(msg, GetPath("logfile")) ;log abbreviated message
   FileAppendLine(ret, GetPath("removeall-logfile")) ;log full message to separate log
}

InstallAll()
{
   ret := CmdRet_Perl("start-MSG-service.pl installall")
   len := strlen(ret)
   msg=Installed all services and the strlen of the installall was %len%
   FileAppendLine(msg, GetPath("logfile")) ;log abbreviated message
   FileAppendLine(ret, GetPath("installall-logfile")) ;log full message to separate log

   if NOT ret
      errord("installall", "(error 1) known issues here: this command returned nothing", ret)
   if InStr(ret, "Cannot start")
      errord("installall", "Couldn't start a service... it returned:", ret)
   if InStr(ret, "***")
      errord("installall", "this command seemed to have an error... it returned:", ret)
   if NOT InStr(ret, "Finished with 0 errors")
      errord("installall", "this command seemed to fail... it returned:", ret)
}

GhettoCmdRet_RunReturn(command, workingDir="", options="")
{
   if InStr(options, "extraGhettoForHighAuth")
   {
      SleepSend("{LWIN}")
      SleepSend("Command Prompt")
      SleepSend("{ENTER}")
   }
   else
      Run, cmd.exe

   ForceWinFocus("(cmd.exe|Command Prompt)", "RegEx")

   if workingDir
   {
      SleepSend("cd " . workingDir)
      SleepSend("{ENTER}")
   }

   SleepSend(command)
   SleepSend("{ENTER}")

   ;TODO should we make something that will close the cmd window at the end?
   ;SleepSend("Y{ENTER}")
   ;SleepSeconds(2)
   ;WinClose
}

autologin(options)
{
   drive := DriveLetter()
   path="%drive%:\LynxCD\Server 7.11\installAssist\autologon.exe"
   if InStr(options, "enable")
   {
      Run, %path% /accepteula
      ForceWinFocus("Autologon")
      SleepSend("{TAB}")
      SleepSend("Administrator")
      SleepSend("{TAB}")
      SleepSend(A_IPaddress1)
      SleepSend("{TAB}")
      SleepSend("Password1!")
      SleepSend("{TAB}")
      SleepSend("{ENTER}")
      SleepSend("{ENTER}")

   }
   else if InStr(options, "disable")
   {
      Run, %path% /accepteula
      ForceWinFocus("Autologon")
      Loop 5
         SleepSend("{TAB}")
      SleepSend("{ENTER}")
      SleepSend("{ENTER}")
   }
   else
   {
      debug("did you misspell the options for autologin?")
   }
}

InstallTTS()
{
   ;WinWaitActive, , &Next
   SleepSeconds(10)
   SleepSend("!n")
   WinWaitActive, , &Yes
   SleepSend("!y")
   WinWaitActive, , &Next
   SleepSend("!n")
   WinWaitActive, , InstallShield Wizard Complete
   SleepClick(360, 350)
}

DriveLetter()
{
   StringLeft, returned, A_ScriptFullPath, 1
   return returned
}

ShortSleep()
{
   SleepSeconds(3)
}

WinLogActiveStats(function, lineNumber)
{
   WinGetActiveStats, winTitle, width, height, xPosition, yPosition
   WinGetText, winText, A
   allVars=function,lineNumber,winTitle,width,height,xPosition,yPosition,winText
   Loop, Parse, allVars, CSV
      %A_LoopField% := A_LoopField . ": " . %A_LoopField%
   delog("Debugging window info", function, lineNumber, winTitle, width, height, xPosition, yPosition, winText)
}

CmdRet_Perl(command)
{
   ;this specifies the full path twice, but it seems to make it more reliable for some reason
   path:="C:\inetpub\wwwroot\cgi\"
   fullCommand=perl %path%%command%
   returned := CmdRet_RunReturn(fullCommand, path)
   return returned
}

lynx_message(message)
{
   global A_LynxMaintenanceType
   if (A_LynxMaintenanceType == "upgrade")
      MsgBox, , Lynx Upgrade Assistant, %message%
   else if (A_LynxMaintenanceType == "install")
      debug("", message)
   else
      MsgBox, , Lynx Technician Assistant, %message%
}

lynx_error(message)
{
   global A_LynxMaintenanceType
      ;MsgBox, , Lynx Upgrade Assistant, %message%
   if (A_LynxMaintenanceType == "upgrade")
      lynx_message("ERROR (Inform Level 2 support): " . message)
   else if (A_LynxMaintenanceType == "install")
      errord("", message)
   else
      lynx_message("ERROR (Inform Level 2 support): " . message)
}

lynx_fatalerror(message)
{
   lynx_error("FATAL " . message)
   ExitApp
}

lynx_log(message)
{
   delog(message)
}

;TODO figure out how this should be different from the normal logs...
; should the filename look like 2011-11-28-important.txt ???
lynx_importantlog(message)
{
   delog(message)
}

;Send an email without doing any of the complex queuing stuff
SendEmailNow(sSubject, sBody, sAttach="", sTo="cameronbaustian@gmail.com", sReplyTo="cameronbaustian+bot@gmail.com")
{
   ;sUsername, sPassword,

   ;item .= SexPanther()

   sFrom     := username . "@gmail.com"

   sServer   := "smtp.gmail.com" ; specify your SMTP server
   nPort     := 465 ; 25
   bTLS      := True ; False
   nSend     := 2   ; cdoSendUsingPort
   nAuth     := 1   ; cdoBasic
   sUsername := "cameronbaustianmitsibot"
   sPassword := GetLynxPassword("email")

   SendTheFrigginEmail(sSubject, sAttach, sTo, sReplyTo, sBody, sUsername, sPassword, sFrom, sServer, nPort, bTLS, nSend, nAuth)
}

GetLynxMaintenanceType()
{
   global Lynx_MaintenanceType
   ;fix the params, if needed
   Lynx_MaintenanceType := StringReplace(Lynx_MaintenanceType, "upgrade", "update")
   if NOT Lynx_MaintenanceType
      Lynx_MaintenanceType := "UNSPECIFIED"
   return Lynx_MaintenanceType
}

SendLogsHome()
{
   ;fix the params, if needed
   reasonForScript := GetLynxMaintenanceType()

   joe := GetLynxPassword("ftp")
   timestamp := CurrentTime("hyphenated")
   date := CurrentTime("hyphendate")
   logFileFullPath := GetPath("logfile")
   logFileFullPath2 := GetPath("checkdb-logfile")
   logFileFullPath3 := GetPath("installall-logfile")

   ;send it back via ftp
   dest=ftp://lynx.mitsi.com/%reasonForScript%_logs/%timestamp%.txt
   dest2=ftp://lynx.mitsi.com/%reasonForScript%_logs/%timestamp%-checkdb.txt
   dest3=ftp://lynx.mitsi.com/%reasonForScript%_logs/%timestamp%-installall.txt
   cmd=C:\Dropbox\Programs\curl\curl.exe --upload-file "%logFileFullPath%" --user AHK:%joe% %dest%
   ret:=CmdRet_RunReturn(cmd)
   cmd=C:\Dropbox\Programs\curl\curl.exe --upload-file "%logFileFullPath2%" --user AHK:%joe% %dest2%
   ret:=CmdRet_RunReturn(cmd)
   cmd=C:\Dropbox\Programs\curl\curl.exe --upload-file "%logFileFullPath3%" --user AHK:%joe% %dest3%
   ret:=CmdRet_RunReturn(cmd)

   ;send it back in an email
   subject=%reasonForScript% Logs
   allLogs=%logFileFullPath%|%logFileFullPath%|%logFileFullPath%
   SendEmailNow(subject, A_ComputerName, allLogs, "cameron@mitsi.com")
}

ShowTrayMessage(message)
{
   quote="
   message := EnsureStartsWith(message, quote)
   message := EnsureEndsWith(message, quote)
   RunAhk("Lynx-NotifyBox.ahk", message)
}

HideTrayMessage(message)
{
   ;get pid (maybe get all pids)
   ;ProcessClose(pid)
}

;TODO Run function with logging
;On second thought, this seems like a really bad idea
;RunFunctionWithLogging(functionName)
;{
   ;if NOT IsFunc(functionName)
      ;return

   ;delog("", "started function", functionName)
   ;%A
   ;delog("", "finished function", functionName)
   ;FIXME the real issue here is that if the functions return early, the function will say that it finished, even though it didn't actually get to the end of it
;}

