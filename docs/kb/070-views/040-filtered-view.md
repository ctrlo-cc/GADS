

# Filter your records using views

**To make it easier to work with the data in your table, you can save filtered views of your records to show only records (rows) that meet specific criteria. If you want to use dates in your filters you need to use the form yyyy-mm-dd.**

To create a filtered view of your data you need to add a new view. You set up your filters using the&nbsp;**Filters form** on the**&nbsp;Add a view**&nbsp;screen.

By default, the first filter you create will have the AND radio button selected. You do not need to change that unless you want to add another filter criteria (see below).

1. Select the field you want the filter to apply to from the dropdown box. (Note that if you change the field you will need to re-enter your search criteria).
2. Use the next two boxes in the row to set the criteria for the filter.
   <br>
   <br>FOR EXAMPLE: If you only wanted to display projects that were in Australia, you might select the *Country*field , then select&nbsp;*equals&nbsp;*from the second box, and then type&nbsp;*Australia&nbsp;*into the final value box.
3. Besides using a filter to look for an exact term or value, you can apply a number of specialised filters. These include:
4. EqualWhen you want an exact match for text or a number.

| Filter  | |
| :--- | :---|
| Not Equal | When you want everything except a specific term or number.|
| Less | When you want to display only the records where the value of this field is less than a specific number, ‘lower’ in the alphabet, or comes before a specific date. |
| Less or Equal |As above, but it also includes records with the value you specify. |
| Greater | When you want to display only the records where the value of this field is greater than a specific number, ‘higher’ in the alphabet or comes after a specific date. |
|Greater or Equal | As above, but it also includes the records with the value you specify.| 
|Begins with | When you want to display only records that begin with a certain word or group of letters. |

You can apply several filters at the same time. To do this you first need to specify whether the next filter is an AND or an OR filter. Use an AND filter if you only want to display records that meet both/all the criteria you set; use an OR filter if you you want to include records that meet either/any of the criteria.
<br>
<br>For example, if you wanted to display projects that were in Australia and South Africa, you would use an OR filter, because you want to view all records where the value for Country is either South Africa or Australia. If you wanted to see all projects that were in Australia and were based in Sydney, you would use an AND filter, because you only want to see records where the County field has the value Australia and the City field has the value Sydney.

You can group your filters to nest different criteria. For example, if you wanted to see projects in either Australia or Japan where the Partner was ABC Corporation, you would add the filter criteria for the countries as sub-group. To do this you would, for example:

Set your first filter as Field &gt; Organisation equal ABC Corporation

Leave the filter type as AND and click the Add group button.

Set your first filter in the group to Field&gt;Country equal Japan

Select the radio button next to OR and click Add rule.

Set your second filter in the group as Field&gt;Country equal Australia

To create a view that only displays records where a date field falls within a specific date range you need to set up criteria for the start date and for the end date. For example, if you wanted to display all projects that ended between 1 January and the 28 February 2015 you would:

Set your first filter as Field &gt; End date greater or equal to (i.e. on or after) 2015-01-01

Select the radio button nest to AND and click Add rule

Set your second filter to Field &gt; End date less or equal to (i.e. before or on) 2015-02-28.