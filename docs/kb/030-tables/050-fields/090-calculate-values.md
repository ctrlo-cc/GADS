

# Using Lua to return values for RAG and calculated fields

**Calculated value fields and RAG status fields automatically generate values based on the values of other fields in a table. For both these field types, you define your calculation using a subset of the Lua programming language.**

**A calculation consists of an `evaluate` function with its parameters being the values required from other fields. You reference the fields you want to evaluate using their short name.**

Here is an example of a calculation that evaluates fields with the short names 'country' and 'region'. It returns the value 'Europe' or 'Japan' depending on the values of those fields:&nbsp;&nbsp;

```lua
function evaluate (country, region)

if country == "Greece" and region == "A" then

return "Europe"

elseif country == "Japan" then

return "Asia"

end

end
```

Using different field types
Values in date fields are passed as Lua table values with the indexes year, month, day and epoch. Date ranges are also passed as Lua tables with the index "from" and "to" which contain tables as per a date field.
Tree values are passed as Lua table values with the indexes "value" and "parents", the former containing the actual value and the latter being another table containing all the node's parents (starting at "parent1" for the top level and continuing sequentially as required).
The ID of the record can be accessed using the special short name "_id".
The user that last updated the record can be accessed using the special short name "_version_user", which will be returned as a table with the keys: firstname, surname, email, telephone, organisation and text. The organisation will be returned with the keys id and name.
Return values
Return values for RedAmberGreen fields should be the string "red", "amber" or "green". It is also permissable to return nothing, which will be interpreted as a grey value. Any other values, or code causing errors, will display purple.
In order for a calculated value to behave as expected (such as sorting and searching correctly), it's important that Linkspace knows what value it is returning. The type of value can specified using the "Return value conversion" option. In the case of a date, the value returned from the calculated function should be epoch time, which will then be converted to a full date by Linkspace.
