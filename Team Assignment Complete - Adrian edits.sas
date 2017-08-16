*=====================================================

Objective 1: 
Create a new master ?le that is completely up to date, error-free, and includes the project classi?cation types.
Incorrect values should not be kept in the new master ?le.
Whenever a correction is made, it should be noted by a ��Yes�� in an appropriately named additional variable.
The new master ?le should be written to a .csv ?le named NewMaster.csv and should contain appropriate headers. 
(You do not need to use SAS to supply the headers.)
Any formatting should be done in SAS.

*Step 1: Merge Assignments & NewForms;

filename NewForms '/folders/myfolders/SAS Programs/Project/NewForms.csv';
data NewForms;
infile NewForms dsd firstobs=2;
input ProjNum Date Hours Stage Complete;
informat Date mmddyy10.;
run;

filename Assigns '/folders/myfolders/SAS Programs/Project/Assignments.csv';
data Assigns;
infile Assigns dsd firstobs=2;
input Consultant $ ProjNum;
run;

filename Master '/folders/myfolders/SAS Programs/Project/Master.csv';
data Mastermap;
infile Master dsd firstobs=2;
input Consultant $ ProjNum;
run;

proc sort data=NewForms;
by ProjNum;
run;

proc sort data=Assigns;
by ProjNum;
run;

proc sort data=Mastermap;
by ProjNum;
run;

data Assigns2;  *combine assignment information from master file and assignment file to retrieve a complete assignment dataset;
retain Consultant ProjNum;
set Assigns Mastermap;
by ProjNum;
if first.ProjNum;
run;

data NF_Merged;
merge Assigns2 NewForms;
by ProjNum;
if date = "" then delete;
run;

*Step 2: Stack NewForms & Master;

filename Master '/folders/myfolders/SAS Programs/Project/Master.csv';
data Master1;
infile Master dsd firstobs=2;
input Consultant $ ProjNum Date Hours Stage Complete;
informat Date mmddyy10.;
run;

proc sort data=Master1;
by ProjNum;
run;

data Master11;
set NF_Merged Master1;
by ProjNum;
run;

*Step 3: Merge New Master & Corrections;

filename Corr '/folders/myfolders/SAS Programs/Project/Corrections.csv';
data Corr;
infile Corr dsd firstobs=2;
input ProjNum Date Hours Stage;
informat Date mmddyy10.;
run;

proc sort data=Corr;
by ProjNum Date;
run;

proc sort data=Master11;
by ProjNum Date;
run;

data Master11H (keep=Consultant ProjNum Date Hours); *split the new master and retain Hours;
set Master11;
run;

data Master11S (keep=Consultant ProjNum Date Stage); *split the new master and retain Stage;
set Master11;
run;

data Corr11H (keep=ProjNum Date Hours); *split the Corrections and retain Hours;
set Corr;
if Hours = "" then delete;
run;

data Corr11S (keep=ProjNum Date Stage);  *split the Corrections and retain Stage;
set Corr;
if Stage = "" then delete;
run;

data Master2H;  *Merge master (Hours only) and Corrections (Hours only) to fill up missing value;
merge Master11H(in=in1) Corr11H(in=in2);
by ProjNum Date;
if in1 & in2 then Revised = "Revised";
run;

data Master2S;  *Merge master (Stage only) and Corrections (Stage only) to fill up missing value;
merge Master11S(in=in1) Corr11S(in=in2);
by ProjNum Date;
if in1 & in2 then Revised1 = "Revised";
run;

data Master2;  *Merge master (Stage only) and master (Hour only);
merge Master2S(in=in1) Master2H(in=in2);
by ProjNum Date;
if Revised1 = "Revised" or Revised = "Revised" then IfRevised = "Yes";
else IfRevised = 'No';
drop Revised1 Revised;
run;

data Master11C (keep=Consultant ProjNum Date Complete);  *split the master11 and retain Complete;
set Master11;
run;

data Master22;  *Merge master (other) and master (Complete only) ;
merge Master2 Master11C;
by ProjNum Date;
run;

*Step 4: Merge Master & ProjClass;

filename PrjC '/folders/myfolders/SAS Programs/Project/ProjClass.csv';
data PrjC;
infile PrjC dsd firstobs=2;
length Type $20; 
input Type $ ProjNum;
run;

proc sort data=PrjC;
by ProjNum;
run;

LIBNAME NMaster '/folders/myfolders/SAS Programs/Project/';
data NMaster.NewMaster; 
retain Consultant ProjNum Type Date Stage Hours IfRevised Complete;
merge Master22 PrjC;
if Hours = "" then Hours = 0;
if Stage = "" then Stage = 0;
by ProjNum;
run;

*Step 5: Write to a CSV file named NewMaster.csv and start from the 2nd line;
title 'Objective 1: Cleaned Master File';
title2 'as of November 4';

ods csv file = "/folders/myfolders/SAS Programs/Project/NewMaster.csv";
proc print data=NMaster.NewMaster;
format Date mmddyy10.;
run;
ods csv close;

*=====================================================

Objective 2: Starting with the new master ?le, generate a report of ongoing projects as of the last entry date (November 4th). 
Ongoing projects are those that have not yet been completed. This report should show only project numbers.;

data NewMaster;
Set NMaster.NewMaster;
Run;

proc sort data=NewMaster;
by ProjNum Date;
run;

*Taking only most recent entry;
data rollup;
set NewMaster;
by ProjNum;
retain ProjNum;
if last.ProjNum then output;
run;

*Taking only incomplete as of last entry;
data incomplete (keep=ProjNum);
set rollup;
if complete=0;
run;

*ATM;
title 'Objective 2: Ongoing Projects Report';
title2 'as of November 4';
proc print data = incomplete noobs label;
label projNum = 'Project Number';
run;

*=====================================================

Objective 3: Starting with the new master ?le, generate a report of the consulting activity of each consultant on each project as of 
the last entry date (November 4th). There should be three separate reports, each showing the project numbers on which the consultant has
worked. For each project the following information should be given: the total number of hours worked, the project type, whether the
project has been completed, the start date of the project, and the end date of the project (determined by the last form submitted for 
the project).;

*=====================================================;

data Smith Brown Jones;
set NewMaster;
if Consultant='Smith' then output Smith;
else if Consultant='Brown' then output Brown;
else output Jones;
run;

data Smith1 (drop=Date Stage Hours IfRevised);
set Smith;
by ProjNum;
retain Hours ProjNum TotalHours StartDate;
if first.ProjNum then do;
	TotalHours=0;
	StartDate=Date;
	end;
TotalHours=TotalHours+Hours;
if last.ProjNum then do;
	EndDate=Date;
	output;
	end;
format EndDate StartDate mmddyy10.
run;

data Brown1 (drop=Date Stage Hours IfRevised);
set Brown;
by ProjNum;
retain Hours ProjNum TotalHours StartDate;
if first.ProjNum then do;
	TotalHours=0;
	StartDate=Date;
	end;
TotalHours=TotalHours+Hours;
if last.ProjNum then do;
	EndDate=Date;
	output;
	end;
format EndDate StartDate mmddyy10.
run;

data Jones1 (drop=Date Stage Hours IfRevised);
set Jones;
by ProjNum;
retain Hours ProjNum TotalHours StartDate;
if first.ProjNum then do;
	TotalHours=0;
	StartDate=Date;
	end;
TotalHours=TotalHours+Hours;
if last.ProjNum then do;
	EndDate=Date;
	output;
	end;
format EndDate StartDate mmddyy10.
run;

*ATM;
title 'Objective 3: Ongoing Consultant Activity';
title2 'as of November 4';
title3 'Smith';
proc print data = Smith1 noobs label;
label projNum = 'Project Number' type = 'Project Type' complete = 'Complete? (1=Yes, 0=No)' totalhours = 'Hours Worked' startdate = 'Start Date' enddate = 'End Date';
run;

title3 'Brown';
proc print data = Brown1 noobs label;
label projNum = 'Project Number' type = 'Project Type' complete = 'Complete? (1=Yes, 0=No)' totalhours = 'Hours Worked' startdate = 'Start Date' enddate = 'End Date';
run;

title3 'Jones';
proc print data = Jones1 noobs label;
label projNum = 'Project Number' type = 'Project Type' complete = 'Complete? (1=Yes, 0=No)' totalhours = 'Hours Worked' startdate = 'Start Date' enddate = 'End Date';
run;

*=====================================================

Objective 4: Overall study of the consulting center

* Graph 1: Overview of the consulting center;

data ConCen(keep=Type Hours);
set NewMaster;
run;

proc sort data = ConCen;
by Type;
run;

data Concen;
set Concen;
by Type;
retain TotalHours;
if first.Type then TotalHours = 0;
	if Hours ^= "" then TotalHours = TotalHours + Hours;
if last.Type then output;
drop Hours;
run;

title 'Overview of the consulting center';
title2 'Objective 4';
proc sgplot data=Concen;
vbar type / response=TotalHours stat=sum;
xaxis grid label='Project Type';
yaxis grid label='Total Hours';
run;

* Graph 2:Look into each consultant;

* Use output of Objective 3;
data comb1;
set Smith1 Jones1 Brown1;
run;

proc sort data = comb1;
by consultant type;
run;

* Aggregate the data;
data comb2;
set comb1;
by consultant type;
retain tot_hours;
if first.consultant and first.type then tot_hours = 0;
if not missing(totalhours) then tot_hours = tot_hours + totalhours;
if last.type then do;
output;
tot_hours=0;
end;
keep Consultant type tot_hours;
run;

* Now graph;
title 'Hours Worked by Consultant and Type';
title2 'Objective 4';
proc sgplot data=comb2;
vbar consultant / response=tot_hours stat=sum group=type nostatlabel
       groupdisplay=cluster;
yaxis grid label='Total Hours';
run;

* Graph 3-4:;

*Create datasets with efficiency metrics for each consultant;
data SmithEffic;
set Smith1;
by ProjNum;
days=EndDate-StartDate;
HoursPerDay=TotalHours/days;
DaysPerHour=days/TotalHours;
run;

data BrownEffic;
set Brown1;
by ProjNum;
days=EndDate-StartDate;
HoursPerDay=TotalHours/days;
DaysPerHour=days/TotalHours;
run;

data JonesEffic;
set Jones1;
by ProjNum;
days=EndDate-StartDate;
HoursPerDay=TotalHours/days;
DaysPerHour=days/TotalHours;
run;

*Sorting for stack;
proc sort data=JonesEffic;
by Consultant ProjNum;
run;

proc sort data=BrownEffic;
by Consultant ProjNum;
run;

proc sort data=SmithEffic;
by Consultant ProjNum;
run;

*Stacking into one dataset;
data Efficiency (keep=Consultant DaysPerHour);
set SmithEffic BrownEffic JonesEffic;
by ProjNum;
run;

*Splitting days per hour into variables for use with sgplot;
data split (keep = SmithDPH BrownDPH JonesDPH);
merge Efficiency(where=(Consultant="Smith") rename=(DaysPerHour=SmithDPH))
       Efficiency(where=(Consultant='Brown') rename=(DaysPerHour=BrownDPH))
       Efficiency(where=(Consultant='Jones') rename=(DaysPerHour=JonesDPH));
run;

*Displays;
title 'Efficiency by Consultant';
title2 'Objective 4';

proc means data=Efficiency mean std min max;
class Consultant;
var DaysPerHour;
run;

proc sgplot data=split;
density SmithDPH / legendlabel='Smith' lineattrs=(pattern=solid);
density BrownDPH / legendlabel='Brown' lineattrs=(pattern=solid);
density JonesDPH / legendlabel='Jones' lineattrs=(pattern=solid);
keylegend / location=inside position=topright across=1;
xaxis label='Days per Hour of Work';
run;


