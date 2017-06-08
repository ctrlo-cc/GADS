

# Control when a field is displayed on the Add/Edit a record screen

**You can choose to hide or display a field on the Add a record or Edit record screens according to the value of another field. **Only showing users fields that are directly relevant can make your Add/Edit record screens less overwhelming. Note that doing this won't limit a user from seeing a field when they are viewing records, only when they are adding or editing them.**

To set the conditions for displaying a field on the **Add a record&nbsp;**or&nbsp;**Edit record screens**:

1. On the Add a field or Edit a field screen, tick the box next to **Only display this field under the following conditions**.
2. Select the field on which your condition should be based from the first drop-down.
3. In the second box, enter the required text of an exact match, or use a regular expression for any other type of match.


   For example:
   
   * If values in a text field must contain the word "project", you could express this condition as: &nbsp;.\*project.\*&nbsp;
   * If &nbsp;all value must start with the letters "BTN", you would express this condition as: BTN.\*
   * If a value has to start with a single letter followed by a number, you would use: [A-Za-z][0-9]+

   [More about regular expressions](http://www.regular-expressions.info/tutorial.html)