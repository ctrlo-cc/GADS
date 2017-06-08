

# Control when a field is displayed on the Add/Edit a record screen

**You can choose to hide or display a field on the Add a record or Edit record screens according to the value of another field. Only showing users fields that are directly relevant can make your Add/Edit a record screens less overwhelming. Doing this won't limit a user from seeing a field when they are viewing records, only when they are adding or editing them.**

To set the conditions for displaying a field on the **Add a record&nbsp;**or&nbsp;**Edit record screens**:

1. On the Add a field or Edit a field screen, tick the box next to **Only display this field under the following conditions**.
2. Select the field on which your condition should be based from the first drop-down.
3. In the second box, enter the required text of an exact match, or use a regular expression for any other type of match.&nbsp;

   For example:

   * If you want the field to be displayed if any value is entered in the other field, you would express this as: .+
   * If you want the field to be displayed only if the value entered in the other field contains the word "project", you could express this condition as: &nbsp;.\*project.\*&nbsp;
   * If you want the field to be displayed only if the value entered in the other field starts with the letters "BTN", you would express this condition as: BTN.\*
   * If you want the field to be displayed only if the value entered in the other field is greater than 300 but less than 1000, you would express this condition as: [3-9][0-9][0-9]
   * If you want the field to be displayed if one of three values it entered in the other field, you would express this as: (value 1|value 2|value 3)
   * If you want the field to be displayed if a specific node in a tree is selected: (.\*#)?Node name

   [More about regular expressions](http://www.regular-expressions.info/tutorial.html)