

# Using regular expressions to match field values

| If you want the field to be displayed if | &nbsp; | &nbsp; | &nbsp; |
| --- | --- | --- | --- |
| The value entered in the other field is an exact match | Enter the text you want to match | &nbsp; | &nbsp; |
| Any value is entered in the other field | .+ | &nbsp; | &nbsp; |
| The value entered in the other field contains the word "project" | \*project.\* | &nbsp; | &nbsp; |
| The value entered in the other field starts with the letters "BTN" | BTN.\* | &nbsp; | &nbsp; |
| The value entered in the other field is greater than 300 but less than 1000 | [3-9][0-9][0-9] | &nbsp; | &nbsp; |
| If one of three values i.e. 1,2 0r 3 is entered in the other field | (1 | 2 | 3) |
| If a specific node in a tree is selected\* | (.\*#)?Node name | &nbsp; | &nbsp; |

\*To include a value from a tree in a regular expression, you need to use the tree node's full path, with a hash between each level. For example, if you were using a tree for your a field on regions, and you only wanted to display a field if a user had selected 'Amhara', you would need to express your match as: "Regions#Africa#Ethiopia#Amhara" i.e. "Level 1#Level 2#Level 3#Node value"

[More about regular expressions](http://www.regular-expressions.info/tutorial.html)