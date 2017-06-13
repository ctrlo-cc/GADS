# Add an RAG status indicator to each record

You can create a RedAmberGreen indicator field to automatically generate colour-coded indicators based on other fields. The conditions for the red, amber and green indicators will always be checked in that order. If a record meets more than one of the con- ditions, it will show the red over the amber or the green.

1.	Add a new data field and give it a name.
2.	Select RedAmberGreen (RAG) status as the Type of field.
3.	Use Basic Perl programming style to stipulate the conditions for red, amber and green indicators to be displayed. If none of the conditions match, the field will be grey.
Values from other fields are used by inserting the field name between square brackets, whilst ”CURDATE” can be used to insert the current date.
For example, if you wanted a green indicator for projects where the start date was in the past you might use:
 


[Start Date] {\textless} CURDATE\newline
Or if you wanted a red alert where a project was over budget you might use:
[Cost to date] > [Budget]
4.	Set the permissions for the field and click Save to create the new data field.

