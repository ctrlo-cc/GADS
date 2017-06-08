

| For an exact match | Enter the text you want to match |
| To match any non-blank value | .+ |
| To match any of three values e.g. 1, 12 and 24 | (1|12|24) |

(1|17|300 \(comment\))

To match a value containing the word ”foo”

.\*foo.\*

To match a value beginning with ”bar”

bar.\*

To match any number between 0 and 9

[0-9]+

To match only the node value of a tree, not including its path:(.\*#)?Node name

To include a value from a tree in a regular expression, you need to use the tree node's full path, with a hash between each level. For example, if you were using a tree for your a field on regions, and you only wanted to display a field if a user had selected 'Amhara', you would need to express your match as: "Regions#Africa#Ethiopia#Amhara" i.e. "Level 1#Level 2#Level 3#Node value"