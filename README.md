# CSV Importer

A CSV importer for godot that supports data import other than the default translations.

## Requirements

This plugin should allow for import of the following formats:

* Comma separated values
* Tab separated values
* Semicolon separated values

The output should be an array containing lists (arrays) for each row in the input-table.

In addition to this, the plugin should also allow for extraction of header-data
and then instead return an array of dictionaries.

Thirdly, the plugin should also support the option of extracting a type-row if there 
is a header. This type-row should then contain the type of each field and be part of 
the output dictionaries in the array.

If the type-row option is not used, there should instead be an option for detecting
booleans, floats and ints.

