# =DelimitedFile a fast minimal file parser designed to operated against well delimited text files.


class DelimitedFile
  # Set the default options.
  # Defaults to:
  # * :field_delimiter = "<COL>"
  # * :row_delimiter   = "<EOL>"
  # * :trim_spaces     = true
  # * :column_case     = :lower, valid options are (:lower, :upper, :retain)
  # * :mode            = :read, valid options are (:read, :write)    
  def initialize(input_file, options = {})
    @input_file = input_file
    @line_number = nil
    @header_cols = []
    @current_line = nil
    @line_number = nil
    @file_opened = false
    
    # Merge in default options
    @options = {
      :row_delimiter    => "<EOL>",
      :field_delimiter  => "<COL>",
      :trim_spaces      => true,
      :column_case      => :lower,
      :mode             => :read
    }.merge(options)

    validate_options(@options)
    
    @field_delimiter = @options[:field_delimiter]
    @row_delimiter = @options[:row_delimiter]
    @mode = @options[:mode]
  end
  
  attr_accessor :header_cols, :current_line, :line_number
  attr_reader :mode
  
  def validate_options(options)
    if options[:field_delimiter].nil?
      raise ArgumentError, ":field_delimiter cannot be nil"
    end

    if options[:row_delimiter].nil?
      raise ArgumentError, ":row_delimiter cannot be nil"
    end

    unless options[:trim_spaces] == true || options[:trim_spaces] == false
      raise ArgumentError, ":trim_spaces must be true or false"
    end
    
    unless [:lower, :upper, :retain].include?(options[:column_case])
      raise ArgumentError, "Invalid :column_case specified.  Valid options are, :lower, :upper, :retain"
    end
    
    unless [:read, :write].include?(options[:mode])
      raise ArgumentError, "Invalid :mode specified.  Valid options are :read, :write"
    end
  end
  
  # Open the file and mark the file_opened flag.
  def open_file(file_name = @input_file)
    @fh = open(file_name, @mode == :read ? 'r' : 'w') unless @file_opened
    @file_opened = true
  end
  
  def close_file(file_name = @input_file)
    @fh.close if @file_opened
    @file_opened = false
  end
  
  def read_guard
    raise ArgumentError, "Cannot iterate through a file unless the file is opened with :mode => :read" unless @mode == :read
  end
  
  def write_guard
    raise ArgumentError, "Cannot write to a file unless the file is opened with :mode => :write" unless @mode == :write
  end
  
  def file_name
    @input_file
  end
  
  # Each iterator will return each *data* row in the file as a hash.
  # Each column will be stored under it's related column name.
  # If you want to get the header columns, call the header_cols attribute
  def each()
    read_guard
    
    output = ''
    
    while output != nil
      begin
        output = next_line
        yield output
      rescue EOFError
        # end of file reached
        output = nil
      end
    end
    
  end
  
  # Similar to each, but yields the line_number as the second parameter.
  # The header row is considered line 0.
  def each_with_index()
    read_guard
    each do |line|
      yield line, @line_number
    end
  end
  
  # Returns each subsequent line in the file until the EOF is reached.
  def next_line
    parse_line(raw_line)
  end
  
  def raw_line
    read_guard
    open_file
    @current_line = @fh.readline(@row_delimiter)
    if @line_number == nil
      @line_number = 0
      @header_cols = parse_header(split_line(@current_line))
      return raw_line
    else
      @line_number += 1
      return split_line(@current_line)
    end
  end
  
  def split_line(line)
    # Passing -1 to split allows it to return trailing null fields
    line.gsub(@row_delimiter, '').split(@field_delimiter, -1)    
  end
  
  # parses each data line of the file and returns a hash with items properly mapped to the header column
  def parse_line(line)
    output_hash = {}
    
    # Trim out extraneous spaces
    if @options[:trim_spaces]
      line.collect! {|el| el.strip}
    end
    
    # loop through each line of the file and assign ech column to a hash 
    # based on the ordinal position of the header column
    line.each_with_index do |element, index|
      output_hash[@header_cols[index]] = element
    end
    
    output_hash
  end
  
  # parses the header line into an Array of columns
  def parse_header(header_line)
    
    header_line.collect {|item|
      case @options[:column_case]
      when :lower
        item.downcase
      when :upper
        item.upcase
      else
        item
      end
    }
  end
  
  def write_file(collection, notification_size = 250)
    write_guard
    
    open_file
    size = collection.size
    
    collection.each_with_index do |line, index|
      @fh.print(generate_header(line)) if index == 0
      @fh.print(generate_line(line))
    end
    
    close_file
  end
  
  def write_header(line)
    write_guard
    open_file
    
    @fh.print(generate_header(line))
  end
  
  def write_line(line)
    write_guard
    open_file
    
    @fh.print(generate_line(line))
  end
  
  # extracts the header line from a given hash
  def generate_header(header_hash)
    # store the keys in case objects come in with hash keys in a different order
    @header_cols = header_hash.keys.collect {|key| key}.sort
    
    keys = @header_cols.collect do |key|
      key_val = key.to_s
      key_val = case @options[:column_case]
      when :lower
        key_val.downcase
      when :upper
        key_val.upcase
      else
        key_val
      end
      key_val
    end
    
    keys.join(@field_delimiter) + @row_delimiter
  end
  
  # extract a line from a given hash using the header column order
  def generate_line(line_hash)
    output_row = []
    @header_cols.each do |key|
      output_row << line_hash[key]
    end
    
    output_row.join(@field_delimiter) + @row_delimiter
  end
  
end