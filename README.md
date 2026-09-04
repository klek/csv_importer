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

## Tests and expected output

Test 00 is a CSV-file without headers

```csv
Apple,Red,true,4.5
Banana,Yellow,false,1
Citrus,Yellow,True,"5,7"
```
Importing this file should result in an array as follows:

```gdscript
[
    ["Apple", "Red", "true", "4.5"],
    ["Banana", "Yellow", "false", "1"],
    ["Citrus", "Yellow", "True", "5,7"]
]
```

Test 01 is a CSV-file with headers

```csv
Fruit,Color,Seeds,Amount
Apple,Red,true,4.5
Banana,Yellow,false,1
Citrus,Yellow,True,"5,7"
```
Importing this file with the following settings:

- Headers = true
- Detect booleans = true
- Detect numbers = true
- Convert decimal point = true

should result in an array as follows:

```gdscript
[
    { "Fruit": "Apple", "Color": "Red", "Seeds": true, "Amount": 4.5 },
    { "Fruit": "Banana", "Color": "Yellow", "Seeds": false, "Amount": 1 },
    { "Fruit": "Citrus", "Color": "Yellow", "Seeds": true, "Amount": 5.7 }
]
```

Test 02 is a CSV-file with headers and a type-row

```csv
Fruit,Color,Seeds,Amount
String,String,Bool,Int
Apple,Red,true,4.5
Banana,Yellow,false,1
Citrus,Yellow,True,"5,7"
```
Importing this file with the following settings:

- Headers = true
- Get row type = true

should result in an array as follows:

```gdscript
[
    { 
        "Fruit": [
            { "type": "String" }, 
            { "value": "Apple" }
        ], 
        "Color": [
            { "type": "String" }, 
            { "value": "Red" }
        ], 
        "Seeds": [
            { "type": "Bool" }, 
            { "value": "true" }
        ], 
        "Amount": [
            { "type": "Float" }, 
            { "value": "4.5" }
        ] 
    }, 
    { 
        "Fruit": [
            { "type": "String" }, 
            { "value": "Banana" }
        ], 
        "Color": [
            { "type": "String" }, 
            { "value": "Yellow" }
        ], 
        "Seeds": [
            { "type": "Bool" }, 
            { "value": "false" }
        ], 
        "Amount": [
            { "type": "Float" }, 
            { "value": "1" }
        ] 
    }, 
    { 
        "Fruit": [
            { "type": "String" }, 
            { "value": "Citrus" }
        ], 
        "Color": [
            { "type": "String" }, 
            { "value": "Yellow" }
        ], 
        "Seeds": [
            { "type": "Bool" }, 
            { "value": "True" }
        ], 
        "Amount": [
            { "type": "Float" }, 
            { "value": "5,7" }
        ] 
    }
]
```

Tests 03-05 should have very similar results but using the tab-character as the
delimiter.

Test 06 is an "empty" CSV-file that just contains 2 empty rows

```csv


```
Importing this file should result in an array as follows:

```gdscript
[]
```

Test 07 is a TSV-file with mismatching fields, ie row 3 (data line 2) has one
extra field

```csv
Customer	Orders	Total	Points
Abe	5	500.24	9000
Colin	2	1000	6000	50
Johan	1	200.3	30
```
Importing this file with the following settings:

- Headers = true

should result in an array as follows:
```gdscript
ERROR: Line 2 has more fields than header
```


