

# Create a graph with metrics

**You can use metrics to convert all the values shown on a graph into percentages of a set of predefined target values. These can be used to monitor key performance indicators (KPIs).&nbsp;**

**For each value on your graph you can set a target. For example, if you need to have a minimum of 150 students achieve a grade A, you could set a metric of 150 for the Grade field**

To create a graph with metrics, you need to create a metric set, and set th

For example, if you were graph might have y-axis values of 20, 40 and 50. These could be plotted against metrics of 40, 40 and 200 (which might be targets). In this case, the graph values would be converted to 50%, 100% and 25%.

Use this page to define a set of metrics to plot graphs against. Each metric must have an x-axis value and a target y-axis value for that point. Once a set of metrics is applied to a graph, each point in that graph will be converted to a percentage as compared to the relevant metric.

For graphs that use a y-axis grouping, it is also necessary to define which y-axis grouping is to be used for each x-axis data point.

X-axis value

This is the value of the x-axis to apply this metric to. Note that if using a date for the x-axis, then this value must be entered as unixtime, having grouped as applicable. For example, if grouping by month, then May 2015 would be entered as 1430438400. Use an online unixtime convertor to calculate the required values.

Y-axis grouping value

This is the value of the group within the x-axis value to apply this metric to. This only applies to graphs that have a "group by" defined.

Target

This is the target value to compare the y-axis value to. The original y-axis value will be compared to this value, and the result displayed on the graph as a releative percentage.

CREATE A SET OF METRICS

One set of metrics consists of several points to plot a graph against. Only users with permission to configure graphs can create met- rics.

1. Click the Admin tab in the top navigation and select Metrics from the drop-down menu. (If you can’t see the Admin tab, then you don’t have the permissions to add, edit or delete data fields or graphs.)
2. Click on **Create new metric set**.
3. Provide a name for your metric set.
4. Click Create.

ADD DATA POINTS TO A METRIC SET

1. Click Edit next to the name of the relevant metric set.
2. To add a metric point, click Add Item.
3. To edit an existing metric point, click Edit next to the item.
4. For each metric point, enter the x-axis value that the metric applies to. The value must be exactly how it is shown on the graph. Also enter the y-axis value that the graph’s value should be ccompared against. Optionally, enter a y-axis grouping value, if the graph in question has a y-axis grouping set (thereby having more than one value per x/y coordinate).
5. Click the Save button.

DELETE A METRIC GROUP

1. Click Edit next to the name of the relevant metric set.
2. Click Delete group.

REMOVE A DATA POINT FROM A METRIC SET

1. Click Edit next to the name of the relevant metric set.

2. Click Edit next to the item.
3. Click Delete.