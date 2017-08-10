# Using Lua to return values for RAG and calculated fields

Calculated value fields and RAG status fields automatically generate values based on the values of other fields in a table. For both these field types, you define your calculation using a sub-set of the Lua programming language. 
A calculation consists of a Lua evaluate function with its parameters being the values required from other fields.   
