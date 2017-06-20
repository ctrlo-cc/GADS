

# Using Lua to return values for RAG and calculated fields

**Calculated value fields and RAG status fields automatically generate values based on the values of other fields in a table. For both these field types, you define your calculation using a subset of the Lua programming language.**

**A calculation consists of an ``evaluate`` function with its parameters being the values required from other fields. You reference the fields you want to evaluate using their short name.**

Here is an example of a calculation that evaluates fields with the short names 'country' and 'region'. It returns the value 'Europe' or 'Japan' depending on the values of those fields:&nbsp;&nbsp;

``function evaluate (country, region)

&nbsp; &nbsp; if country == "Greece" and region == "A" then

&nbsp; &nbsp; &nbsp; &nbsp; return "Europe"

&nbsp; &nbsp; elseif country == "Japan" then

&nbsp; &nbsp; &nbsp; &nbsp; return "Asia"

&nbsp; &nbsp; end

end``