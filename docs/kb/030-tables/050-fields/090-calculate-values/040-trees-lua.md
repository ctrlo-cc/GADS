# Working tree fields in your Lua calculations
Tree values are passed as Lua table values with the indexes *value* and *parents*. *Value* contains the actual value and *parents* is another table containing all the node's parents (starting at *parent1* for the top level and continuing sequentially).

## Example of calculated values based on tree nodes

```
function evaluate (regions)
    if parent1.parent2.value == nil then
        return "This is a country-wide project"
end
```