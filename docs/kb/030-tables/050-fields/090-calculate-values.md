

# Using Lua to return values for RAG and calculated fields

**Calculated value fields and RAG status fields automatically generate values based on the values of other fields in a table. For both these field types, you define your calculation using a subset of the Lua programming language.**

**A calculation consists of an**`**evaluate**`** function with parameters as the values required from other fields. You reference the fields you want to evaluate using their short name.**