# Package for formatting JSON data in
# YAML-style, perfect for CLI output

# Export package
module.exports = exports

# Module dependencies
Utils  = require('./utils')
fs = require('fs')

# Package version
exports.version = JSON.parse(fs.readFileSync(__dirname + '/../package.json', 'utf8')).version

### Render function
  *Parameters:*

  * **`data`**: Data to render
  * **`options`**: Hash with different options to configure the parser
  * **`indentation`**: Base indentation of the parsed output

  *Example of options hash:*
    
     {
       emptyArrayMsg: '(empty)', // Rendered message on empty strings
       defaultIndentation: 2     // Indentation on nested objects
     }
###
exports.render = (data, options, indentation) ->

  # Default value for the indentation param
  indentation = indentation || 0
  
  # Default values for the options
  options = options || {}
  options.emptyArrayMsg = options.emptyArrayMsg || '(empty array)'
  options.defaultIndentation = options.defaultIndentation || 2
  
  # Initialize the output (it's an array of lines)
  output = []
  
  # Helper function to detect if an object can be serializable directly
  isSerializable = (input) ->
    if typeof input is 'string' or typeof input is 'boolean' or
        typeof input is 'number' or input is null
      return true
    
    return false

  # Render a string exactly equal
  if isSerializable(data)
    output.push Utils.indent(indentation) + data
  else 
    if Array.isArray(data)
      # If the array is empty, render the `emptyArrayMsg`
      if data.length is 0
        output.push Utils.indent(indentation) + options.emptyArrayMsg
      else
        data.forEach (element) ->
          # Prepend the dash at the begining of each array's element line
          line = Utils.indent(indentation) + '- '
      
          # If the element of the array is a string, render it in the same line
          if typeof element is 'string'
            line += exports.render element, options
            output.push line
          # If the element of the array is an array or object, render it in next line
          else
            output.push line
            output.push exports.render(element, options, indentation + options.defaultIndentation)
    else
      if typeof data is 'object'
        # Get the size of the longest index to render all the values on the same column
        maxIndexLength = Utils.getMaxIndexLength(data)
        key
    
        sortedKeys = (Object.keys data).sort()

        for i in sortedKeys
          # Prepend the index at the beginning of the line
          key = Utils.indent(indentation) + i + ': '

          # If the value is serializable, render it in the same line
          if isSerializable data[i]
            key += exports.render data[i], options, maxIndexLength - i.length
            output.push key
          # If the index is an array or object, render it in next line
          else
            output.push key
            output.push exports.render(data[i], options, indentation + options.defaultIndentation)
  # Return all the lines as a string
  output.join '\n'