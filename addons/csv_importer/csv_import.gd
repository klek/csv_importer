@tool
extends EditorImportPlugin

const PLUGIN_NAME : String = "CSV Importer"
const PLUGIN_UNIQUE_NAME : String = "csv_importer"


# NOTE(klek): Should there be presets? 
enum Presets {
    DEFAULT,
}

# Supported delimiters
enum Delimiters {
    UNKNOWN     = -1,
    COMMA       =  0,
    TAB         =  1,
    SEMICOLON   =  2,
}

func _get_importer_name() -> String:
    return PLUGIN_UNIQUE_NAME


func _get_visible_name() -> String:
    return PLUGIN_NAME


func _get_priority() -> float:
    return 2.0


func _get_import_order() -> int:
    return 0


func _get_recognized_extensions() -> PackedStringArray:
    return ["csv", "tsv"]


func _get_save_extension() -> String:
    return "res"


func _get_resource_type() -> String:
    # TODO(klek): What resource type should we return
    return "Resource"


func _get_preset_count() -> int:
    return Presets.size()


func _get_preset_name(preset_index: int) -> String:
    match preset_index:
        Presets.DEFAULT:
            return "Comma separated value with headers"
        _:
            return "Unknown"


func _get_import_options(path: String, preset_index: int) -> Array[Dictionary]:
    var delim : int = Delimiters.COMMA
    var headers : bool = false
    match preset_index:
        # NOTE(klek): We don't handle regular CSV, because it is the defaults
        Presets.DEFAULT:
            delim = Delimiters.COMMA
            headers = true
    # Return the options available
    return [
        {
            name            = "delimiter",
            default_value   = delim,
            property_hint   = PROPERTY_HINT_ENUM,
            hint_string     = "Comma,Tab,Semicolon"
        },
        {
            name            = "headers",
            default_value   = headers,
            usage           = PROPERTY_USAGE_DEFAULT | PROPERTY_USAGE_UPDATE_ALL_IF_MODIFIED
        },
        # Adds the possibility of having a type row below a header row, which
        # desribes the type of each field
        {
            name            = "get_type_row",
            default_value   = false,
            usage           = PROPERTY_USAGE_DEFAULT | PROPERTY_USAGE_UPDATE_ALL_IF_MODIFIED
        },
        {
            name            = "detect_booleans",
            default_value   = false
        },
        {
            name            = "detect_numbers",
            default_value   = false,
            usage           = PROPERTY_USAGE_DEFAULT | PROPERTY_USAGE_UPDATE_ALL_IF_MODIFIED
        },
        {
            name            = "force_float",
            default_value   = false
        },
        {
            name            = "convert_decimal_delimiter",
            default_value   = false
        },
    ]


func _get_option_visibility(path: String, option_name: StringName, options: Dictionary) -> bool:
    # Only show option to get types if headers is used
    if ( option_name == &"get_type_row" ):
        return bool( options.get( &"headers", false ) )
    # Only show option to detect booleans if headers is used
    if ( option_name == &"detect_booleans" ):
        return bool( options.get( &"headers", false ) &&
                     !options.get( &"get_type_row", false ) )
    # Only show option to detect numbers if headers is used
    if ( option_name == &"detect_numbers" ):
        return bool( options.get( &"headers", false ) &&
                     !options.get( &"get_type_row", false ) )
    # Only show option to force floats if detect_numbers is true
    if ( option_name == &"force_float" ):
        return bool( options.get( &"headers", false ) &&
                     options.get( &"detect_numbers", false ) &&
                     !options.get( &"get_type_row", false ) )
    # Only show option to convert the decimal delimiter if detect_numbers is true
    if ( option_name == &"convert_decimal_delimiter" ):
        return bool( options.get( &"headers", false ) &&
                     options.get( &"detect_numbers", false ) &&
                     !options.get( &"get_type_row", false ) )
    # Always show all other options
    return true


func _import( source_file: String, save_path: String,
              options: Dictionary, platform_variants: Array[String],
              gen_files: Array[String]) -> Error:
    # Setup the delimiter
    var delim : String
    var delim_num : int = options.get( &"delimiter", Delimiters.UNKNOWN )
    if ( delim_num != Delimiters.UNKNOWN ):
        # Determine the delimiter
        match delim_num:
            Delimiters.COMMA:
                delim = ","
            Delimiters.TAB:
                delim = "\t"
            Delimiters.SEMICOLON:
                delim = ";"
    else:
        # Setting default value as a comma
        delim = ","
    # Try to open the file
    var file : FileAccess = FileAccess.open( source_file, FileAccess.READ )
    if ( file == null ):
        printerr( "Failed to open file: ", source_file )
        return FileAccess.get_open_error()
    # File is opened, now we build an array of packed strings ( each of the rows )
    var rows : Array[ PackedStringArray ] = []
    # Loop through the file, and add each line as a separate entry
    while ( file.get_position() < file.get_length() ):
        # Get the current line split into each field, based on  the specified
        # delimiter and add it to the array
        var line : PackedStringArray = file.get_csv_line( delim )
        rows.append( line )
    # Close the file
    file.close()
    # DEBUG
    print( rows )

    # Remove any potential trailing empty rows by checking the size and content
    # of the last line
    if ( !rows.is_empty() && rows.back().size() == 1 && rows.back()[0] == "" ):
        rows.pop_back()
    # DEBUG
    print( rows )

    # Setup the resource
    var data : CSVData = preload( "csv_data.gd" ).new()

    # Are headers specified, such that we can build a dictionary?
    if ( options.get( &"headers", false ) ):
        var start_point : int = 0
        if ( rows.is_empty() ):
            printerr( "Cannot find header in empty file" )
            return ERR_PARSE_ERROR
        # Headers are assumed to be the first line
        var headers : PackedStringArray = rows[ start_point ]
        start_point += 1
        # Set data.is_dictionaries to true
        data.is_dictionaries = true

        # TODO(klek): Add extraction of the typed row
        var type_row : PackedStringArray = []
        if ( options.get( &"get_type_row", false ) && ( rows.size() > start_point ) ):
            type_row = rows[ start_point ]
            start_point += 1
            # Now we must check that the sizes of header and type row are equal
            if ( headers.size() != type_row.size() ):
                printerr( "Typed array is different size than header" )
                return ERR_PARSE_ERROR
            # Set type information in data
            data.contains_type_info = true

        # Loop through each following line
        for i in range( start_point, rows.size() ):
            # Should we really use a type here?
            var fields : PackedStringArray = rows[ i ]
            # Check that the number of fields match the size of the header
            if ( fields.size() > headers.size() ):
                printerr( "Line %d has more fields than header" % i )
                return ERR_PARSE_ERROR

            # Build a dictionary from all the fields
            var dict : Dictionary[ String, Variant ] = {}
            for j in headers.size():
                # Grab the current field name
                var name : String = headers[ j ]
                var value : Variant = null
                # Are we within limits?
                if ( ( j < fields.size() ) && !options.get( &"get_type_row", false ) ):
                    var curr_field : String = fields[ j ]
                    # Should we detect numbers?
                    #if ( options.get( &"detect_numbers", false ) && curr_field.is_valid_float() ):
                    if ( options.get( &"detect_numbers", false ) && _is_str_valid_float( curr_field ) ):
                        # Should we convert to decimal point numbers?
                        if ( options.get( &"convert_decimal_delimiter", false ) ):
                            curr_field = curr_field.replace( ',', '.')
                        # Should we not force floats?
                        if ( !options.get( &"force_float", false ) && curr_field.is_valid_int() ):
                            value = int( curr_field )
                        else:
                            # Forcing floats
                            value = float( curr_field )
                    # Should we detect booleans?
                    elif ( options.get( &"detect_booleans", false ) && 
                           ( curr_field.nocasecmp_to("false") == 0 ) ):
                        # Is this a false?
                        value = false
                    elif ( options.get( &"detect_booleans", false ) && 
                           ( curr_field.nocasecmp_to("true") == 0 ) ):
                        # Is this a true?
                        value = true
                    else:
                        # Just regular add
                        value = curr_field
                # Adding the type if this is specified in options
                elif ( options.get( &"get_type_row", false ) ):
                    var new_arr : Array[ Dictionary ] = []
                    var type_dict : Dictionary[ String, String ] = {}
                    var value_dict : Dictionary[ String, String ] = {}
                    type_dict[ "type" ] = type_row[ j ]
                    # Add the type dictionary
                    new_arr.append( type_dict )
                    # Check bounds
                    if ( j < fields.size() ):
                        value_dict[ "value" ] = fields[ j ]
                    else:
                        # We have an empty field
                        type_dict[ "value" ] = ""
                    # Add the value dictionary
                    new_arr.append( value_dict )
                    # Assign the new dictionaly to value
                    value = new_arr
                # Finally store
                dict[ name ] = value
            # DEBUG
            print( dict )
            # Append it to our dictionary
            data.records.append( dict )

    # We cannot build a dictionary for each line, since headers was not true
    else:
        # The data stored is a simple array
        data.is_dictionaries = false
        data.records = rows

    # DEBUG
    print( "The data stored is: ", data.records )

    # Save the resource
    var filename : String = save_path + "." + _get_save_extension()
    #print( filename )
    var err : Error = ResourceSaver.save( data, filename )
    if ( err != OK ):
        printerr( "Failed to save the resource" )
    return err


## Helper function to determine if a string is a float. Basically copies the C++
## implementation for string.is_valid_float(), but also adds a "," (comma) as a valid
## delimiter
func _is_str_valid_float( str: String ) -> bool:
    var len : int = str.length()

    if ( len == 0 ):
        return false

    var from : int = 0
    if ( str[0] == '+' || str[0] == '-'):
        from += 1

    var exponent_found : bool = false
    var period_found : bool = false
    var sign_found : bool = false
    var exponent_values_found : bool = false
    var numbers_found : bool = false

    for i in range( from , len ):
        var c : String = str[ i ]
        if ( c.is_valid_int() ): 
            if ( exponent_found ):
                exponent_values_found = true
            else:
                numbers_found = true
        elif ( numbers_found && !exponent_found && ( c == 'e' || c == 'E' ) ):
            exponent_found = true
        elif ( !period_found && !exponent_found && ( c == '.' || c == ',' ) ):
            period_found = true
        elif ( ( c == '-' || c == '+' ) && exponent_found && !exponent_values_found && !sign_found ):
            sign_found = true
        else:
            # no start with number plz
            return false

    return numbers_found
