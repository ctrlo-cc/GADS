

# Using Lua to return values for RAG and calculated fields

**Calculated value fields and RAG status fields automatically generate values based on the values of other fields in a table. For both these field types, you define your calculation using a subset of the Lua programming language.&nbsp;****A calculation consists of an `evaluate` function with its parameters being the values required from other fields. &nbsp;**&nbsp;

You reference the fields you want to evaluate using their short name inside round brackets. You include any field values in inverted commas. For example if you wanted to create an automatically generated 'continent' field that depended on the values in the 'country' and 'region' fields, you might use the following calculation for the 'continent' field:

```lua
function evaluate (country, region)

if country == "Greece" and region == "A" then

return "Europe"

elseif country == "Japan" then

return "Asia"

end

end
```

## &nbsp;

## RedAmberGreen calcuations

The return values for the calculation in an RAG status field should be "red", "amber" or "green". You can also return nothing, which will be interpreted as grey. Any other values, or code causing errors, will display purple.

RAG for appraisal due/overdue
```lua


function evaluate (nxtappr)

if nxtappr == nil 


if nxtappr == nil

then return "red"

end

nxapptable = os.date("\*t", nxtappr.epoch) --convert next appr to a lua table

if nxapptable.year &gt; os.date("\*t").year &nbsp; -- if next appr is next year - must be green

then return "green"

elseif nxapptable.month == os.date("\*t").month -- if next appr is current month = amber

then return "amber"

elseif nxapptable.month &lt; os.date("\*t").month -- if next appr month past - then red

then return "red"

else

return "green"

end

end
```

In order for a calculated value to behave as expected (such as sorting and searching correctly), it's important that Linkspace knows what value it is returning. The type of value can specified using the "Return value conversion" option. In the case of a date, the value returned from the calculated function should be epoch time, which will then be converted to a full date by Linkspace.

## Using different field types in your calculations

### Date fields

Values in date fields are parsed as Lua table values with the indexes year, month, day and epoch.

Date ranges are also passed as Lua tables with the index "from" and "to" which contain tables as per a date field.

Tree values are passed as Lua table values with the indexes "value" and "parents", the former containing the actual value and the latter being another table containing all the node's parents (starting at "parent1" for the top level and continuing sequentially as required).

The ID of the record can be accessed using the special short name "_id".

The user that last updated the record can be accessed using the special short name "_version_user", which will be returned as a table with the keys: firstname, surname, email, telephone, organisation and text.

The organisation will be returned with the keys id and name.