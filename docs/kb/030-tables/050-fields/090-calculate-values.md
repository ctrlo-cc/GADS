

# Using Lua to return values for RAG and calculated fields

**Calculated value fields and RAG status fields automatically generate values based on the values of other fields in a table. For both these field types, you define your calculation using a subset of the Lua programming language.&nbsp;****A calculation consists of an `evaluate` function with its parameters being the values required from other fields. &nbsp;**&nbsp;

You reference the fields you want to evaluate using their short name inside round brackets. You include any field values in inverted commas. For example if you wanted to create an automatically generated *continent&nbsp;*field that depended on the values in the *country&nbsp;*and *region&nbsp;*fields, you might use the following calculation for the *continent&nbsp;*field:

```lua
function evaluate (country, region)

if country == "Greece" and region == "A" then

return "Europe"

elseif country == "Japan" then

return "Asia"

end

end
```

## Using different field types in your calculations

### Date fields

Values in** date fields** are parsed as Lua table values with the indexes year, month, day and epoch.&nbsp;

Tables are the means for structuring data in Lua. You use tables to represent ordinary arrays, symbol tables, sets, records, queues, and other data structures. You create tables by means of a constructor expression, which in its simplest form is written as {} &nbsp;More about Lua tables

**Date ranges** are also passed as Lua tables with the index "from" and "to" which contain tables as per a date field.

Tree values are passed as Lua table values with the indexes "value" and "parents", the former containing the actual value and the latter being another table containing all the node's parents (starting at "parent1" for the top level and continuing sequentially as required).

The ID of the record can be accessed using the special short name "_id".

The user that last updated the record can be accessed using the special short name "_version_user", which will be returned as a table with the keys: firstname, surname, email, telephone, organisation and text.

The organisation will be returned with the keys id and name.

## RedAmberGreen calcuations

The return values for the calculation in an RAG status field should be 'red', 'amber' or 'green'. You can also return nothing, which will be interpreted as grey. Any other values, or code causing errors, will display purple.

For example, if you wanted to use a RAG status field to flag reports that were done (green), due (amber) or overdue (red), you could do this using the &nbsp;date field that shows when a report is due (short name = report_date):&nbsp;

```lua

function evaluate (report_date)
report_datetable = os.date("\\\*t", report_date.epoch) -- make date table
if report_datetable.month == os.date("\\\*t").month -- super done this month
then return "green"
elseif report_datetable.month == os.date("\\\*t").month-1 -- due this month
then return "amber"
elseif s_datet.month > os.date("\\\*t").month-2 -- overdue
then return "red"
else -- something very wrong
return "red"
end
end
```

In order for a calculated value to behave as expected (such as sorting and searching correctly), it's important that Linkspace knows what value it is returning. The type of value can specified using the "Return value conversion" option. In the case of a date, the value returned from the calculated function should be epoch time, which will then be converted to a full date by Linkspace.

## &nbsp;