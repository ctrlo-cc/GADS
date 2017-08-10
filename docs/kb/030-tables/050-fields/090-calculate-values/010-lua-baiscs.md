
# Lua - the very basics



### In Lua the relational operators are: 
•	Equal to ==
•	Not equal to ~= 
•	Less than < 
•	Greater than > 
•	Less than or equal to <= 
•	Greater than or equal to >= 
### The arithmetic operators are: 
•	add + 
•	subtract – 
•	multiply *  
•	divide /


## Specifying the type of value you want your Lua calculation to return

**For a calculated value to behave as expected (such as sorting and searching correctly), it's important that Linkspace knows what type of value it is.**

For a calculated field you need to specify the format of your returned value in the **Return value conversion dropdown box**. In Linkspace, the value type can be *string*, *integer*, *decimal*or *date*.&nbsp;

Where the returned value is a date, it should be in epoch time, which will then be converted to a full date by Linkspace.&nbsp;

For a RAG status field your returned value is automatically formatted as a string (with the values being “red”, “amber” or “green”).