

# Add an RAG status indicator to each record

**You can use a RedAmberGreen (RAG) indicator field to automatically generate colour-coded indicators based on the values of other fields in a record. The conditions for the red, amber and green indicators will always be checked in that order. If a record meets more than one of the conditions, it will show the red over the amber or the green.**

1. Add a new field and give it a name.
2. Select RedAmberGreen (RAG) status as the Type of field.
3. Use basic Lua programming to stipulate the conditions for red, amber and green indicators to be displayed. If none of the conditions match, the field will be grey. See: Using Lua in Linkspace
4. Set the permissions for the field and click Save to create the new data field.