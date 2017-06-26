

# Create a graph with metrics

**You can use metrics to convert the total counts of the values shown on a graph into percentages of a set of predefined target values. These can be used to monitor goals or key performance indicators (KPIs).&nbsp;**

To create a graph with metrics, you need to first create a metric set, then add a series of target metrics to that set. Once you've done that you can create a new graph where you use your metric set.&nbsp;

## Create a metric set

1. Select the table for which you want to create a graph from the&nbsp;**Table dropdown** list at the top of your screen.
2. Navigate to the records screen by clicking on **Records** in the main menu and selecting **See records**&nbsp;from the dropdown menu.&nbsp;
3. Click on the&nbsp;**Manage views**&nbsp;dropdown button and select&nbsp;**Manage metrics**.
4. Click the&nbsp;**Create new metric set&nbsp;**button.
5. Give your metric set a name. Click **Create**.

## Add metrics to your metric set

Once you have created your metric set you will be returned to the **Manage metrics** screen.&nbsp;

1. Click **Edit**next to the name of the metric set.&nbsp;
2. Click **Add target metric**
3. Each target metric must have an **X-axis field value** and a **target metric**. The target metric will be compared to the count or sum of the Y-axis field you select for your graph. If you group the Y-axis values in your graph, then in the **Y-axis grouping value** box, you need to specify the value for Y-axis grouping field that your metric applies to.&nbsp;
   <br>
   <br>**Example:** You need to have a minimum of 150 students achieve a grade A, 200 achieve a grade B, and 300 achieve a grade C. You create a graph where the X-axis is the *Grade&nbsp;*field. Next you create a set of grade metrics. To the set you add a target metric for each grade. The first target metric has the X-axis value A and the target metric 150; the second metric has the X-axis value B and the target value 200; the third metric has X-axis value C and a target metric of 300. &nbsp;If the total number of A, B and C grades is 100, 200 and 150 respectively, then on your graph you would see A grades as 75%, B grades as 100%, and C grades as 50%.&nbsp;

Once a set of metrics is applied to a graph, each point in that graph will be converted to a percentage as compared to the relevant metric.

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