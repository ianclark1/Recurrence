<!---
Copyright 2009 Chris Blackwell Email: chris@m0nk3y.net

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>
--->

<cfcomponent>
	
	<cffunction name="createDailyRecurrence" output="false" access="public" returntype="query">
		<cfargument name="fromdate" type="date" required="yes">
		<cfargument name="todate" type="date" required="yes">
		<cfargument name="dayInterval" type="numeric" required="no" default="1">
		<cfset var ret = querynew("recdate")>
		<cfset var curdate = parseDate(arguments.fromdate)>
		<cfset arguments.dayInterval = abs(arguments.dayInterval) />
	
		<cfscript>
		// return if we're given daft dates
		if(arguments.todate LT arguments.fromdate) {
			return ret;
		}

		while(curdate LTE arguments.todate) {
			pos = queryaddrow(ret);
			querysetcell(ret, "recdate", curdate, pos);
			curdate = dateadd("d", arguments.dayInterval, curdate);
		}
		return ret;
		</cfscript>
	</cffunction>
	
	<cffunction name="createWeeklyRecurrence" output="false" access="public" returntype="query">
		<cfargument name="fromdate" type="date" required="yes">
		<cfargument name="todate" type="date" required="yes">
		<cfargument name="days" type="string" required="yes" hint="List of day numbers eg: 1,3,5 (week runs sun[1] to sat[7] as is the CF default)">
		<cfargument name="weekInterval" type="numeric" required="no" default="1">
		<cfset var ret = querynew("recdate")>
		<!--- make this the first date in the week, we'll drop under runs later--->
		<cfset var curdate = firstDateOfWeek(arguments.fromdate)>
		<cfset var daylist = listsort(arguments.days, "Numeric")>
		<cfset var i = 1>
		<cfset arguments.weekInterval = abs(arguments.weekInterval) />

		<cfscript>
		// return if we're given daft dates
		if(arguments.todate LT arguments.fromdate) {
			return ret;
		}

		// Loop in whole week intervals
		while(curdate LTE arguments.todate) {
			// Add everyday requested for the week, drop overruns later
			for(i=1; i LTE listlen(daylist); i=i+1) {
				pos = queryaddrow(ret);
				querysetcell(ret, "recdate", dateadd("d", listgetat(daylist, i)-1, curdate), pos);
			}
			curdate = dateadd("ww", arguments.weekInterval, curdate);
		}
		</cfscript>

		<!--- drop any over/under runs --->		
		<cfquery name="ret" dbtype="query">
		SELECT * FROM ret 
		WHERE recdate >= <cfqueryparam cfsqltype="cf_sql_date" value="#arguments.fromdate#">
		AND recdate <= <cfqueryparam cfsqltype="cf_sql_date" value="#arguments.todate#">
		</cfquery>
		
		<cfreturn ret>	
	</cffunction>

	<cffunction name="createMonthlyDateRecurrence" output="false" access="public" returntype="query">
		<cfargument name="fromdate" type="date" required="yes">
		<cfargument name="todate" type="date" required="yes">
		<cfargument name="day" type="numeric" required="yes">
		<cfargument name="monthInterval" type="numeric" required="no" default="1">
		<cfset var ret = querynew("recdate")>
		<cfset var curdate = parseDate(arguments.fromdate)>
		<cfset var daysthismonth = 0>
		<cfset var tmpDay = 1>
		<cfset arguments.monthInterval = abs(arguments.monthInterval) />		
		

		<cfscript>
		// return if we're given daft dates
		if(arguments.todate LT arguments.fromdate) {
			return ret;
		}

		daysthismonth = daysinmonth(createdate(year(curdate), month(curdate), 1));
		if(arguments.day GT daysthismonth) tmpDay = daysthismonth;
		else tmpDay = arguments.day;

		if(arguments.fromdate LTE createdate(year(arguments.fromdate), month(arguments.fromdate), tmpDay)) {
			curdate = createdate(year(arguments.fromdate), month(arguments.fromdate), tmpDay);
		}
		else {
			curdate = dateadd("m", 1, curdate);
			curdate = createdate(year(curdate), month(curdate), tmpDay);
		}
		
		while(curdate LTE arguments.todate) {
			pos = queryaddrow(ret);
			querysetcell(ret, "recdate", curdate, pos);
			
			curdate = dateadd("m", arguments.monthInterval, curdate);
			daysthismonth = daysinmonth(createdate(year(curdate), month(curdate), 1));
			if(arguments.day GT daysthismonth) tmpDay = daysthismonth;
			else tmpDay = arguments.day;
			curdate = createdate(year(curdate), month(curdate), tmpDay);
		}

		</cfscript>

		<!--- drop any over/under runs --->		
		<cfquery name="ret" dbtype="query">
		SELECT * FROM ret 
		WHERE recdate >= <cfqueryparam cfsqltype="cf_sql_date" value="#arguments.fromdate#">
		AND recdate <= <cfqueryparam cfsqltype="cf_sql_date" value="#arguments.todate#">
		</cfquery>

		
		<cfreturn ret>	
	</cffunction>

	<cffunction name="createMonthlyOrdinalRecurrence" output="false" access="public" returntype="query">
		<cfargument name="fromdate" type="date" required="yes">
		<cfargument name="todate" type="date" required="yes">
		<cfargument name="ordinal" type="numeric" required="yes" hint="allowed values are: 1,2,3,4 or 5 for last of month">
		<cfargument name="day" type="numeric" required="yes" hint="sun[1] to sat[7], or 0 for 'day'">
		<cfargument name="monthInterval" type="numeric" required="no" default="1">
		<cfset var ret = querynew("recdate")>
		<cfset var curdate = createdate(year(arguments.fromdate), month(arguments.fromdate), 1)>
		<cfset var aMonths = arraynew(1)>
		<cfset var i = 0>
		<cfset var tmpDay = 1>
		<cfset arguments.monthInterval = abs(arguments.monthInterval) />			

		<cfscript>
		// return if we're given daft dates
		if(arguments.todate LT arguments.fromdate) {
			return ret;
		}

		while(curdate LTE arguments.todate) {
			arrayappend(aMonths, curdate);
			curdate = dateadd("m", arguments.monthInterval, curdate);
		}

		if(arguments.day EQ 0) {
			for(i=1; i LTE arraylen(aMonths); i=i+1) {
				pos = queryaddrow(ret);
				if(ordinal LTE 4) tmpDay = ordinal;
				else tmpDay = daysinmonth(aMonths[i]);
				querysetcell(ret, "recdate", createdate(year(aMonths[i]), month(aMonths[i]), tmpDay), pos);
			}
		}
		else if(arguments.day LTE 7) {
			for(i=1; i LTE arraylen(aMonths); i=i+1) {
				pos = queryaddrow(ret);
				querysetcell(ret, "recdate", getNthDayXofMonth(aMonths[i], ordinal, day), pos);
			}
		}
		</cfscript>

		<!--- drop any over/under runs --->		
		<cfquery name="ret" dbtype="query">
		SELECT * FROM ret 
		WHERE recdate >= <cfqueryparam cfsqltype="cf_sql_date" value="#arguments.fromdate#">
		AND recdate <= <cfqueryparam cfsqltype="cf_sql_date" value="#arguments.todate#">
		</cfquery>

		
		<cfreturn ret>	
	</cffunction>

	<cffunction name="createYearlyRecurrence" output="false" access="public" returntype="query">
		<cfargument name="fromdate" type="date" required="yes">
		<cfargument name="todate" type="date" required="yes">
		<cfargument name="day" type="numeric" required="yes">
		<cfargument name="month" type="numeric" required="yes">
		<cfargument name="yearInterval" type="numeric" required="no" default="1">
		<cfset var ret = querynew("recdate")>
		<cfset var curdate = parseDate(arguments.fromdate)>
		<cfset var daysthismonth = 0>
		<cfset var tmpDay = 1>
		<cfset arguments.yearInterval = abs(arguments.yearInterval) />	

		<cfscript>
		// return if we're given daft dates
		if(arguments.todate LT arguments.fromdate) {
			return ret;
		}
		
		if(arguments.fromdate LTE createdate(year(arguments.fromdate), arguments.month, arguments.day)) {
			curdate = createdate(year(arguments.fromdate), arguments.month, arguments.day);
		}
		else {
			curdate = createdate(year(arguments.fromdate)+1, arguments.month, arguments.day);
		}
		
		while(curdate LTE arguments.todate) {
			pos = queryaddrow(ret);
			querysetcell(ret, "recdate", curdate, pos);
			daysthismonth = daysinmonth(createdate(year(curdate)+arguments.yearInterval, month(curdate), 1));
			if(arguments.day GT daysthismonth) tmpDay = daysthismonth;
			else tmpDay = arguments.day;
			
			curdate = createdate(year(curdate)+arguments.yearInterval, month(curdate), tmpDay);
		}
		return ret;
		</cfscript>
	
	</cffunction>

	<cffunction name="firstDateOfWeek" output="false" access="private" returntype="date" hint="Utility function to find the first date (Sunday) of the week in which <em>date</em> occurs">
		<cfargument name="date" type="date" required="true">
		<cfscript>
		d1 = arguments.date;
		dow = dayofweek(d1);
		if(dow EQ 0) dow = 7;
		diff = dow-1;
		diff = diff-(2*diff);
		d2 = dateadd("d", diff, d1);
		return d2;
		</cfscript>		
	</cffunction>
	
	<cffunction name="getNthDayXofMonth" output="false" access="private" returntype="date">
		<cfargument name="date" type="date" required="yes">
		<cfargument name="ordinal" type="numeric" required="yes">
		<cfargument name="day" type="numeric" required="yes">
		<cfset var aDates = arraynew(1)>
		<cfset theDay = 1>
		<cfset theDate = "">

		<cfscript>
		while( dayOfWeek( createDate( year(date), month(date), theDay)) NEQ arguments.day) {
			theDay = theDay + 1;		
		}
		theDate = createDate( year(date), month(date), theDay);
		arrayappend(aDates, theDate);
		while (month(dateAdd('d',7,theDate)) EQ month(date)) {
			theDate = dateAdd('d',7,theDate);
			arrayappend(aDates, theDate);
		}
		if(ordinal GTE arraylen(aDates)) {
			return aDates[arraylen(aDates)];
		}
		else {
			return aDates[ordinal];
		}		

		</cfscript>
	</cffunction>

	<cffunction name="parseDate" access="private">
		<cfargument name="date" type="date" required="yes" />
		<cfset var d = createDate(year(date), month(date), day(date)) />
		<cfreturn d />
	</cffunction>

	
</cfcomponent>