#Working with dates in your Lua calculations
##Date fields
Values in Linkspace date fields are passed as Lua table values with the indexes year, month, day and epoch. (Tables are how you structure data in Lua. Learn more about Lua tables) 
You can reference the operating system date and time by using os.time. 
### Example of a calculation for a RAG field that uses dates

For example, you could use a RAG status field to keep track of reviews.  Completed reviews would be “green”, those scheduled within the next 30 days would be “amber” and those with no scheduled date would be “red”. 

```
function evaluate (reviewdate)
    
if reviewdate == nil then
            return "red"
    end
    
if reviewdate.epoch < os.time() then
        return "green"
    end
    if reviewdate.epoch < os.time() + (86400 * 30) then
        return "amber"
    end
	
end

```
In this calculation you reference the current date using os.time, and convert the time to epoch time. 
See below for a full list of the Lua functions that are enabled in Linkspace

### Date range fields
Date ranges are also passed as Lua tables with the table indexes from and to which contain the same tables a date field would (i.e. with the tables indexes year, month, day and epoch).
Example of calculated values using a date range field
```

function evaluate (projectschedule)
    if projectschedule == nil then
        return "No project schedule"
    end
    if projectschedule.from.epoch < os.time() then
        return "Project underway"
    end
    if projectschedule.from.epoch < os.time() + (86400 * 30) then
        return "Starts within 30 days"
    end
    return "Not yet started"
end
```