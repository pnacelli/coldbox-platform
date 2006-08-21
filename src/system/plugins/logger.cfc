<!-----------------------------------------------------------------------Author: Luis MajanoDate:   September 27, 2005Description: This is the framework's logger object. It performs all necessary			 loggin procedures.Modifications:09/25/2005 - Created the template.10/13/2005 - Updated the reqCollection to the request scope.12/18/2005 - Using mailserverSettings from config.xml now, fixed structnew for default to logError12/20/2005 - Bug on spaces for log files.02/16/2006 - Fixes for subjects06/28/2006 - Updates for coldbox07/12/2006 - Tracer updates-----------------------------------------------------------------------><cfcomponent name="logger"			 hint="This is the frameworks logger object. It is used for all logging facilities."			 extends="coldbox.system.plugin">			 <!------------------------------------------- CONSTRUCTOR ------------------------------------------->	<!--- ************************************************************* --->	<cffunction name="init" access="public" returntype="any" hint="Constructor" output="false">		<cfset super.Init() />		<cfset variables.instance.pluginName = "Logger">		<cfset variables.instance.pluginVersion = "1.0">		<cfset variables.instance.pluginDescription = "This plugin is used for logging methods and facilities.">		<!--- This plugin's properties --->		<!--- log name without extension --->		<cfset variables.instance.logfilename = URLEncodedFormat(replace(replace(getSetting("AppName")," ","","all"),".","_","all"))>		<!--- The full absolute path of the log file --->		<cfset variables.instance.logFullPath = getSetting("ColdboxLogsLocation")>		<!--- Available valid severities --->		<cfset variables.instance.validSeverities = "information|fatal|warning|error">		<!--- Return --->		<cfreturn this>	</cffunction>	<!--- ************************************************************* --->	<!------------------------------------------- PUBLIC ------------------------------------------->	<!--- ************************************************************* --->	<cffunction name="tracer" access="Public" hint="Log a trace message" output="false" returntype="void">		<!--- ************************************************************* --->		<cfargument name="message"    hint="Message to Send" type="string" required="Yes" >		<cfargument name="ExtraInfo"  hint="Extra Information to dump on the trace" required="No" default="" type="any">		<!--- ************************************************************* --->		<cfscript>		var tracerEntry = StructNew();		if ( not valueExists("tracerStack") )			setValue("tracerStack",ArrayNew(1));		//Insert Message & Info		StructInsert(tracerEntry,"message", arguments.message);		if ( not isSimpleValue(arguments.ExtraInfo) )			StructInsert(tracerEntry,"ExtraInfo", duplicate(arguments.ExtraInfo));		else			StructInsert(tracerEntry,"ExtraInfo", arguments.ExtraInfo);		   ArrayAppend(getValue("tracerStack"),tracerEntry);		</cfscript>	</cffunction>	<!--- ************************************************************* --->	<!--- ************************************************************* --->	<cffunction name="logErrorWithBean" access="public" hint="Log an error into the framework using a coldbox exceptionBean" output="false" returntype="void">		<!--- ************************************************************* --->		<cfargument name="ExceptionBean" 	type="any" 	required="yes">		<!--- ************************************************************* --->		<!--- Initialize variables --->		<cfset var Exception = arguments.ExceptionBean>		<cfset var BugReport = "">		<cfset var logSubject = "">		<cfset var errorText = "">		<cfset var arrayTagContext = "">		<cfset var myStringBuffer = "">		<cftry>			<cfif getSetting("EnableColdfusionLogging") or getSetting("EnableColdboxLogging")>				<!--- Log Entry in the Logs --->				<cfif isStruct(Exception.getExceptionStruct())>					<cfset myStringBuffer = getPlugin("StringBuffer").setup(BufferLength=500)>					<cfif Exception.getType() neq  "">						<cfset myStringBuffer.append( "CFErrorType=" & Exception.getType() & chr(13) )>					</cfif>					<cfif Exception.getDetail() neq  "">						<cfset myStringBuffer.append("CFDetails=" & Exception.getDetail() & chr(13) )>					</cfif> 					<cfif Exception.getMessage() neq "">						<cfset myStringBuffer.append("CFMessage=" & Exception.getMessage() & chr(13) )>					</cfif>					<cfif Exception.getStackTrace() neq "">						<cfset myStringBuffer.append("CFStackTrace=" & Exception.getStackTrace() & chr(13) )>					</cfif>					<cfif Exception.getTagContextAsString() neq "">						<cfset myStringBuffer.append("CFTagContext=" & Exception.getTagContextAsString() & chr(13) )>					</cfif>							</cfif>				<!--- Log the Entry --->				<cfset logEntry("error","Custom Error Message: #Exception.getExtraMessage()#",myStringBuffer.getString() )>			</cfif>			<cfcatch type="any"><!---Silent Failure---></cfcatch>		</cftry>				<!--- Check if Bug Reports are Enabled, then send Email Bug Report --->		<cfif getSetting("EnableBugReports") and getSetting("BugEmails") neq "">			<cftry>			<!--- Save the Bug Report --->			<cfsavecontent variable="BugReport"><cfinclude template="../includes/BugReport.cfm"></cfsavecontent>			<!--- Setup The Subject --->			<cfset logSubject = "#getSetting("Codename",1)# Bug Report: #getSetting("Environment")# - #getSetting("appname")#">			<!--- Check for Custom Mail Settings or use CFMX Administrator Settings --->			<cfif getSetting("MailServer") neq "">				<!--- Mail New Bug --->				<cfmail to="#getSetting("BugEmails")#"						from="#getSetting("OwnerEmail")#"						subject="#logSubject#"						type="html"						server="#getSetting("MailServer")#"						username="#getSetting("MailUsername")#"						password="#getSetting("MailPassword")#">#BugReport#</cfmail>			<cfelse>				<!--- Mail New Bug --->				<cfmail to="#getSetting("BugEmails")#"						from="#getSetting("OwnerEmail")#"						subject="#logSubject#"						type="html"						username="#getSetting("MailUsername")#"						password="#getSetting("MailPassword")#">#BugReport#</cfmail>			</cfif>				<cfcatch type="any"><!---Silent Failure---></cfcatch>			</cftry>		</cfif>	</cffunction>	<!--- ************************************************************* --->	<!--- ************************************************************* --->	<cffunction name="logError" access="public" hint="Log an error into the framework using arguments. Facade to logErrorWithBean." output="false" returntype="void">		<!--- ************************************************************* --->		<cfargument name="Message" 			type="string" 	required="yes">		<cfargument name="ExceptionStruct" 	type="any"    	required="no" default="#StructNew()#" hint="The CF cfcatch structure.">		<cfargument name="ExtraInfo"  		type="any"    	required="no" default="">		<!--- ************************************************************* --->		<cfset logErrorWithBean(getPlugin("beanFactory").create("coldbox.system.beans.exception").init(arguments.ExceptionStruct,arguments.message,arguments.ExtraInfo))>	</cffunction>	<!--- ************************************************************* --->		<!--- ************************************************************* --->	<cffunction name="logEntry" access="public" hint="Log a message to the Coldfusion/Coldbox Logging Facilities if enabled via the config.xml" output="false" returntype="void">		<!--- ************************************************************* --->		<cfargument name="Severity" 		type="string" 	required="yes" hint="Valid Severities are #getValidSeverities()#">		<cfargument name="Message" 			type="string"  	required="yes" hint="The message to log.">		<cfargument name="ExtraInfo"		type="string"   required="no"  default="" hint="Extra information to append.">		<!--- ************************************************************* --->		<cfset var FileWriter = "">		<cfmodule template="../includes/timer.cfm" timertag="LogEntry [#arguments.severity#]">						<!--- Check for Severity via RE --->			<cfif not reFindNoCase("^(#getValidSeverities()#)$",arguments.Severity)>				<cfthrow type="Framework.plugins.logger.InvalidSeverityException" message="The severity you entered: #arguments.severity# is an invalid severity. Valid severities are #getValidSeverities()#.">			</cfif>							<!--- Check for Coldfusion Logging --->			<cfif getSetting("EnableColdfusionLogging")>				<!--- Coldfusion Log Entry --->				<cflog type="#trim(lcase(arguments.severity))#"					   text="#arguments.message# & #chr(13)# & ExtraInfo: #arguments.ExtraInfo#" 					   file="#getLogFileName()#">						</cfif>						<!--- Check For Coldbox Logging --->			<cfif getSetting("EnableColdboxLogging")>								<!--- Check for Log File --->				<cfif not FileExists(getlogFullPath())>					<!--- File has been deleted, reinit the log location --->					<cfset initLogLocation(false)>					<!--- Log the occurrence recursively--->					<cfset logEntry("warning","Log Location had to be reinitialized. The file: #getLogFullPath()# was not found when trying to do a log.")>				</cfif>								<!--- Check Rotation --->				<cfset checkRotation()>								<cflock type="exclusive" name="LogFileWriter" timeout="120">					<!--- Init FileWriter --->					<cftry>						<cfset FileWriter = getPlugin("FileWriter").setup(getlogFullPath(),getSetting("LogFileEncoding",1),getSetting("LogFileBufferSize",1),true)>						<cfcatch type="any">							<cfthrow type="Framework.plugins.logger.CreatingFileWriterException" message="An error occurred creating the java FileWriter utility plugin." detail="#cfcatch.Detail#<br>#cfcatch.message#">						</cfcatch>					</cftry>										<!--- Log a new Entry --->					<cftry>						<cfset FileWriter.writeLine(formatLogEntry(arguments.severity,arguments.message,arguments.extraInfo))>						<cfset FileWriter.close()>						<cfcatch type="any">							<!--- Close FileWriter First --->							<cfset FileWriter.close()>							<cfthrow type="Framework.plugins.logger.WritingFirstEntryException" message="An error occurred writing the first entry to the log file." detail="#cfcatch.Detail#<br>#cfcatch.message#">						</cfcatch>					</cftry>				</cflock>			</cfif>		</cfmodule>	</cffunction>	<!--- ************************************************************* --->	<!--- ************************************************************* --->	<cffunction name="initLogLocation" access="public" hint="Initialize the ColdBox log location." output="false" returntype="void">		<!--- ************************************************************* --->		<cfargument name="firstRunFlag" default="true" type="boolean" required="false" hint="This is true when ran from the configloader, to run the setupLogLocationVariables() method.">		<!--- ************************************************************* --->		<cfset var FileWriter = "">		<cfset var InitString = "">		<cfmodule template="../includes/timer.cfm" timertag="Initializing Coldbox Log Location">						<!--- Determine First Run --->			<cfif arguments.firstRunFlag>				<!--- Setup Log Location Variables --->				<cfset setupLogLocationVariables()>			</cfif>									<!--- Create Log File if It does not exist and initialize it. --->			<cfif not fileExists(getLogFullPath())>				<cflock name="LogFileWriter" type="exclusive" timeout="120">				<cftry>					<!--- Create Log File --->					<cfset getPlugin("fileUtilities").createFile(getLogFullPath())>					<!--- Check if we can write to the file --->					<cfif not getPlugin("fileUtilities").FileCanWrite(getLogFullPath())>						<cfthrow type="Framework.plugins.logger.LogFileNotWritableException" message="The log file: #getLogFullPath()# is not a writable file. Please check your operating system's permissions.">					</cfif>					<cfcatch type="any">						<cfthrow type="Framework.plugins.logger.CreatingLogFileException" message="An error occurred creating the log file at #getLogFullPath()#." detail="#cfcatch.Detail#<br>#cfcatch.message#">					</cfcatch>				</cftry>								<cftry>					<!--- Init the Log File, with framework's default encoding and buffer size --->					<cfset FileWriter = getPlugin("FileWriter").setup(getLogFullPath(),getSetting("LogFileEncoding",1),getSetting("LogFileBufferSize",1))>					<cfcatch type="any">						<cfthrow type="Framework.plugins.logger.CreatingFileWriterException" message="An error occurred creating the java FileWriter utility plugin." detail="#cfcatch.Detail#<br>#cfcatch.message#">					</cfcatch>				</cftry>								<cftry>					<!--- 						Log Format						"[severity]" "[date]" "[time]" "[message]" "[extrainfo]"					--->					<cfset InitString = '"Severity","Date","Time","Message","ExtraInfo"'>					<cfset FileWriter.writeLine(InitString)>					<cfset FileWriter.writeLine(formatLogEntry("info","The log file has been initialized successfully by ColdBox.","Log file: #getLogFullPath()#; Encoding: #getSetting("LogFileEncoding",1)#; BufferSize: #getSetting("LogFileBufferSize",1)#"))>					<cfset FileWriter.close()>					<cfcatch type="any">						<!--- Close FileWriter First --->						<cfset FileWriter.close()>						<cfthrow type="Framework.plugins.logger.WritingFirstEntryException" message="An error occurred writing the first entry to the log file." detail="#cfcatch.Detail#<br>#cfcatch.message#">					</cfcatch>				</cftry>				</cflock>								</cfif>					</cfmodule>	</cffunction>	<!--- ************************************************************* --->	<!--- ************************************************************* --->	<cffunction name="removeLogFile" access="public" hint="Removes the log file" output="false" returntype="void">		<!--- ************************************************************* --->		<cfargument name="reinitializeFlag" required="false" default="true" type="boolean" hint="Flag to reinitialize the log location or not." >		<!--- ************************************************************* --->		<cflock name="LogFileWriter" type="exclusive" timeout="120">			<cfset getPlugin("fileUtilities").removeFile(getLogFullPath())>		</cflock>		<cfif arguments.reinitializeFlag>			<cfset initLogLocation(false)>		</cfif>	</cffunction>	<!--- ************************************************************* --->	<!------------------------------------------- PUBLIC ACCESSOR/MUTATORS ------------------------------------------->		<!--- ************************************************************* --->	<cffunction name="setLogFileName" access="public" hint="Set the logfilename" output="false" returntype="void">		<!--- ************************************************************* --->		<cfargument name="filename" 		type="string" 	required="yes" hint="The filename to set">		<!--- ************************************************************* --->		<cfset instance.logfilename = arguments.filename>		</cffunction>	<!--- ************************************************************* --->		<!--- ************************************************************* --->	<cffunction name="getLogFileName" access="public" hint="Get the logfilename" output="false" returntype="string">		<cfreturn instance.logfilename >	</cffunction>	<!--- ************************************************************* --->		<!--- ************************************************************* --->	<cffunction name="setlogFullPath" access="public" hint="Set the logFullPath" output="false" returntype="void">		<!--- ************************************************************* --->		<cfargument name="logFullPath" 		type="string" 	required="yes" hint="The logFullPath to set">		<!--- ************************************************************* --->		<cfset instance.logFullPath = arguments.logFullPath>		</cffunction>	<!--- ************************************************************* --->		<!--- ************************************************************* --->	<cffunction name="getlogFullPath" access="public" hint="Get the logFullPath" output="false" returntype="string">		<cfreturn instance.logFullPath >	</cffunction>	<!--- ************************************************************* --->		<!--- ************************************************************* --->	<cffunction name="getvalidSeverities" access="public" hint="Get the validSeverities" output="false" returntype="string">		<cfreturn instance.validSeverities >	</cffunction>	<!--- ************************************************************* --->		<!------------------------------------------- PRIVATE ------------------------------------------->		<!--- ************************************************************* --->	<cffunction name="formatLogEntry" access="private" hint="Format a log request into the specified entry format." output="false" returntype="string">		<!--- ************************************************************* --->		<cfargument name="Severity" 		type="string" 	required="yes" hint="error|warning|info">		<cfargument name="Message" 			type="string"  	required="yes" hint="The message to log.">		<cfargument name="ExtraInfo"		type="string"   required="no" default="" hint="Extra information to append.">		<!--- ************************************************************* --->		<!--- Manipulate Arguments --->		<cfset arguments.severity = trim(lcase(arguments.severity))>		<cfset arguments.Message = replacenocase(arguments.message,chr(34),'','all')>		<cfset arguments.ExtraInfo = replacenocase(arguments.ExtraInfo,chr(34),'','all')>		<cfreturn '"#arguments.Severity#","#dateformat(now(),"MM/DD/YYYY")#","#timeformat(now(),"HH:MM:SS")#","#arguments.message#","#arguments.extrainfo#"'>	</cffunction>	<!--- ************************************************************* --->		<!--- ************************************************************* --->	<cffunction name="setupLogLocationVariables" access="private" hint="Setup the log location variables." output="false" returntype="void">		<!--- Test for Relative Path First --->		<cfif directoryExists(expandPath(getSetting("ColdboxLogsLocation")))>			<!--- It is a relative path, once expanded. Save this as the location. --->			<cfset setSetting("ColdboxLogsLocation", expandPath(getSetting("ColdboxLogsLocation"))) >		<cfelseif not directoryExists(getSetting("ColdboxLogsLocation"))>			<!--- Directory not verified by relative or absolute, throw error --->			<cfthrow type="Framework.plugins.logger.ColdboxLogsLocationNotFoundException" message="The directory: #getSetting("ColdboxLogsLocation")# cannot be located or does not exist. Please verify your entry in your config.xml.cfm">		</cfif>				<!--- Then set the complete log path and save. --->		<cfset setSetting("ColdboxLogsLocation",getSetting("ColdboxLogsLocation") & getSetting("OSFileSeparator",1) & getLogFileName() & ".log")>		<cfset setlogFullPath(getSetting("ColdboxLogsLocation"))>	</cffunction>	<!--- ************************************************************* --->		<!--- ************************************************************* --->	<cffunction name="checkRotation" access="private" hint="Checks the log file size. If greater than framework's settings, then zip and rotate." output="false" returntype="void">		<cfset var zipFileName = getDirectoryFromPath(getlogFullPath()) & getLogFileName() & "." & dateformat(now(),"MM.DD.YY") & timeformat(now(),".HH.MM") & ".zip">		<!--- Verify FileSize --->		<cfif getPlugin("fileUtilities").FileSize(getlogFullPath()) gt (getSetting("LogFileMaxSize",1) * 1024)>			<cfmodule template="../includes/timer.cfm" timertag="Archiving And Rotating Log File">			<!--- Archive file and rotate log --->			<cftry>				<!--- Zip Log File --->				<cflock name="LogFileWriter" type="exclusive" timeout="120">					<cfset getPlugin("zip").AddFiles(zipFileName,getlogFullPath(),"","",false,9,false )>				</cflock>				<!--- Clean & reinit Log File --->				<cfset removeLogFile(true)>				<cfcatch type="any">					<cfset logEntry("error","Could not zip and rotate log files.","#cfcatch.Detail# #cfcatch.Message#")>				</cfcatch>			</cftry>			</cfmodule>		</cfif>	</cffunction>	<!--- ************************************************************* --->			</cfcomponent>