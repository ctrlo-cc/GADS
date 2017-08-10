# Accessing record IDs in your Lua calculations
You can access the ID field of a record using the special short name "_id".
You can access the user who last updated the record using the special short name "_version_user", which will be returned as a Lua table with the indexes: firstname, surname, email, telephone, organisation and text. The organisation will be returned with the indexes id and name.
