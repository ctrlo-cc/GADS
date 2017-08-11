# Working tree fields in your Lua calculations
Tree values are passed as Lua table values with the indexes *value* and *parents*. *Value* contains the actual value and *parents* is another table containing all the node's parents (starting at *parent1* for the top level and continuing sequentially).

## Example of calculated values based on tree nodes

```
function evaluate (mytree)
    if mytree.parents.parent2 == nil then
        return "No level 2 value selected"
end
```