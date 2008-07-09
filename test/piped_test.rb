require 'test/unit'
require File.join(File.dirname(__FILE__), '../lib', 'piped')

class PipedTest < Test::Unit::TestCase
  def initialize(value)
    super(value)
  end
  
  # Create the default DelimitedFile object pointing to the test data.
  def setup
    @df = DelimitedFile.new(data_file_fn)
  end

  # Test basic header row parsing.
  def test_header_row_default_options
    header = "first<COL>last<COL>age"
    
    df = DelimitedFile.new("")
    header_cols = df.parse_header(header)
    
    assert_equal(3, header_cols.size)
  end

  # Test column_case => :upper
  def test_column_case_upper
    header = "First<COL>Last<COL>Age"
    
    df = DelimitedFile.new(data_file_fn, :column_case => :upper)
    header_cols = df.parse_header(header)
    
    assert_equal(3, header_cols.size)
    assert_equal('FIRST', header_cols[0])
    assert_equal('LAST', header_cols[1])
    assert_equal('AGE', header_cols[2])
  end
  
  # Test column_case => :retain
  def test_column_case_retain
    header = "First<COL>Last<COL>Age"
    
    df = DelimitedFile.new(data_file_fn, :column_case => :retain)
    header_cols = df.parse_header(header)
    
    assert_equal(3, header_cols.size)
    assert_equal('First', header_cols[0])
    assert_equal('Last', header_cols[1])
    assert_equal('Age', header_cols[2])
  end  
  
  
  # Test header row parsing with a different delimiter.
  def test_header_row_different_delimiter
    header = "first;last;age"
    
    df = DelimitedFile.new("", :field_delimiter => ";")
    header_cols = df.parse_header(header)
    
    assert_equal(3,       header_cols.size)
    assert_equal('first', header_cols[0])
    assert_equal('last',  header_cols[1])
    assert_equal('age',   header_cols[2])
  end
  
  # This tests the basic operation of the DelimitedFile class.
  def test_piped_data
    df = @df

    line = df.next_line
    
    assert_equal(3,         line.keys.size)
    assert_equal('doug',    line['first'])
    assert_equal('tolton',  line['last'])
    assert_equal('32',      line['age'])
    assert_equal(1,         df.line_number)
    
    line = df.next_line
    
    assert_equal(3,         line.keys.size)
    assert_equal('torrey',  line['first'])
    assert_equal('tolton',  line['last'])
    assert_equal('30',      line['age'])
    assert_equal(2,         df.line_number)
    
  end
  
  # Tests piped with trim_spaces turned off.
  def test_piped_data_not_trimmed
    df = DelimitedFile.new(data_file_fn, :trim_spaces => false)
    
    # pop the line we don't care about
    df.next_line
    line = df.next_line
    
    assert_equal('  torrey  ',    line['first'])
    assert_equal('  tolton',      line['last'])
    assert_equal('30  ',          line['age'])
    
  end
  
  # Tests piped with an empty trailing column.
  def test_empty_column
    df = @df
    
    # pop the two lines we don't care about
    df.next_line
    df.next_line
    line = df.next_line
    
    assert_equal(3,         line.keys.size)
    assert_equal('lisa',    line['first'])
    assert_equal('tolton',  line['last'])
    assert_equal('',        line['age'])
    assert_equal(3,         df.line_number)
  end
  
  # Test the each iterator.  Make sure the line counts are as expected.
  def test_each_iterator
    df = @df
    
    df.each do |line|
      assert_equal(3, line.keys.size)
    end
    
    assert_equal(3, df.line_number)
  end
  
  # Make sure the each_with_index iterator is correctly incrementing the line_number.
  def test_each_with_index
    df = @df
    
    i = 1
    
    df.each_with_index do |line, index|
      assert_equal(i, index)
      i += 1
    end
  end
  
  # shortcut function to get the name of the test data file.
  def data_file_fn
    File.join(File.dirname(__FILE__), 'test_data.txt')
  end
  
end