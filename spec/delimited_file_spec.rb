require File.join(File.dirname(__FILE__), '../lib/delimited_file')


describe DelimitedFile do
  
  def data_file_fn
    File.join(File.dirname(__FILE__), 'test_data.txt')
  end
   
  before(:each) do
    @df = DelimitedFile.new(data_file_fn)
  end

  describe "Header Parsing" do
  
    before(:each) do
      @header = "first<COL>last<COL>age"
    end
  
    it "should be able to parse header rows"  do
      df = DelimitedFile.new("")
      header_cols = df.parse_header(df.split_line(@header))

      header_cols.size.should == 3
    end
    
    it "should upper case the column names" do
      header = "First<COL>Last<COL>Age"

      df = DelimitedFile.new("", :column_case => :upper)
      header_cols = df.parse_header(df.split_line(@header))

      header_cols.size.should == 3
      header_cols[0].should == 'FIRST'
      header_cols[1].should == 'LAST'
      header_cols[2].should == 'AGE'
    end
    
    it "should retain the case of the column names" do
      header = "First<COL>Last<COL>Age"

      df = DelimitedFile.new("", :column_case => :retain)
      header_cols = df.parse_header(df.split_line(header))

      header_cols[0].should == 'First'
      header_cols[1].should == 'Last'
      header_cols[2].should == 'Age'
    end
    
    it "should properly parse the header file with a specified column delimiter" do
      header = "first;last;age"

      df = DelimitedFile.new("", :field_delimiter => ";")
      header_cols = df.parse_header(df.split_line(header))

      header_cols.size.should == 3
      header_cols[0].should == 'first'
      header_cols[1].should == 'last'
      header_cols[2].should == 'age'
    end
  end
  
  describe "general read parser operation" do
    it "should successfully parse the test data file" do

      line = @df.next_line
      line.keys.size.should == 3
      line['first'].should == 'doug'
      line['last'].should == 'tolton'
      line['age'].should == "32"
      @df.line_number.should == 1
      
      line = @df.next_line
      line.keys.size.should == 3
      line['first'].should == 'torrey'
      line['last'].should == 'tolton'
      line['age'].should == "30"
      @df.line_number.should == 2
    end
    
    it "should preserve whitespace if trimming whitespace is disabled" do
      df = DelimitedFile.new(data_file_fn, :trim_spaces => false)

      # pop the line we don't care about
      df.next_line
      line = df.next_line

      line['first'].should == '  torrey  '
      line['last'].should == '  tolton'
      line['age'].should == '30  '
    end
    
    it "should work properly with an empty trailing column" do
      # pop the two lines we don't care about
      @df.next_line
      @df.next_line
      line = @df.next_line

      line.keys.size.should == 3
      line['first'].should == 'lisa'
      line['last'].should == 'tolton'
      line['age'].should == ''
      @df.line_number.should == 3
    end
    
    it "should iterate through the lines with the each method" do
      # Test the each iterator.  Make sure the line counts are as expected.
      @df.each do |line|
        line.keys.size.should == 3
      end

      @df.line_number.should == 3
    end 
    
    it "should populate the number properly when using each_with_index" do
      # Make sure the each_with_index iterator is correctly incrementing the line_number.
        i = 1

        @df.each_with_index do |line, index|
          index.should == i
          i += 1
        end
    end
  end

  describe "Parser operation based on mode setting" do
    it "should default to read only mode" do
      df = DelimitedFile.new("")
      df.mode.should == :read
    end
    
    it "should raise an ArgumentError trying to iterate with each, through a file opened in :write mode" do
      df = DelimitedFile.new("", :mode => :write)
      df.mode.should == :write
      lambda { df.each {|line| line} }.should raise_error(ArgumentError)
      lambda { df.each_with_index {|line, index| line} }.should raise_error(ArgumentError)
      lambda { df.next_line }.should raise_error(ArgumentError)
    end

    it "should raise an ArgumentError trying to iterate with each_with_index, through a file opened in :write mode" do
      df = DelimitedFile.new("", :mode => :write)
      df.mode.should == :write
      lambda { df.each_with_index {|line, index| line} }.should raise_error(ArgumentError)
    end

    it "should raise an ArgumentError trying to iterate with next_line, through a file opened in :write mode" do
      df = DelimitedFile.new("", :mode => :write)
      df.mode.should == :write
      lambda { df.next_line }.should raise_error(ArgumentError)
    end


  end
  
  describe "Valid Option handling" do
    it "should raise an error :field_delimiter is set to nil" do
      lambda { df = DelimitedFile.new("", :field_delimiter => nil)  }.should raise_error(ArgumentError)
    end
    
    it "should raise an error :row_delimiter is set to nil" do
      lambda { df = DelimitedFile.new("", :row_delimiter => nil)  }.should raise_error(ArgumentError)
    end
  end
  
  describe "general file writing operation" do
    before(:each) do
      @dfw = DelimitedFile.new("/tmp/blah", :mode => :write)
      @data = [ 
                {"first" => "doug", "last" => "tolton", "age" => 32},
                {"last" => "tolton", "age" => 30, "first" => "torrey"},
                {"age" => nil, "first" => "lisa", "last" => "tolton"}
              ]
      @data1 = [ 
                {"First" => "doug", "Last" => "tolton", "Age" => 32},
                {"First" => "torrey", "Last" => "tolton", "Age" => 30},
                {"First" => "lisa", "Last" => "tolton", "Age" => nil}
              ]
      
    end
    
    it "should generate a header line given a hash" do
      header_output = @dfw.generate_header(@data[0])
      header_output.should =~ /first/
      header_output.should =~ /last/
      header_output.should =~ /age/
      
    end
    
    it "should capitalize the header columns" do
      dfw = DelimitedFile.new('', :mode => :write, :column_case => :upper)
      header_output = dfw.generate_header(@data[0])
      header_output.should =~ /FIRST/
      header_output.should =~ /LAST/
      header_output.should =~ /AGE/
    end
    
    it "should lower case the header columns" do
      dfw = DelimitedFile.new('', :mode => :write, :column_case => :lower)
      header_output = dfw.generate_header(@data1[0])
      header_output.should =~ /first/
      header_output.should =~ /last/
      header_output.should =~ /age/
    end
    
    it "should retain the original case of the object" do
      dfw = DelimitedFile.new('', :mode => :write, :column_case => :retain)
      header_output = dfw.generate_header(@data1[0])
      header_output.should =~ /First/
      header_output.should =~ /Last/
      header_output.should =~ /Age/
    end
    
    it "should extract the columns from the hash" do
      dfw = DelimitedFile.new('', :mode => :write)
      header_output = dfw.generate_header(@data[0])
      dfw.header_cols.include?('first').should == true
      dfw.header_cols.include?('last').should == true
      dfw.header_cols.include?('age').should == true
    end
    
    it "should generate a delimited line" do
      dfw = DelimitedFile.new('', :mode => :write)
      header = dfw.generate_header(@data[0])
      line = dfw.generate_line(@data[0])
      line.should == "32<COL>doug<COL>tolton<EOL>"
    end
    
    it "should generate a delimited line even with nil values" do
      dfw = DelimitedFile.new('', :mode => :write)
      header = dfw.generate_header(@data[0])
      line = dfw.generate_line(@data[2])
      line.should == "<COL>lisa<COL>tolton<EOL>"
    end
    
    it "should write delimited files given a collection of hashes" do
      dfw = DelimitedFile.new('/tmp/output', :mode => :write)
      dfw.write_file(@data)
      fh = open('/tmp/output', 'r')
      content = fh.read()
      content.should == "age<COL>first<COL>last<EOL>32<COL>doug<COL>tolton<EOL>30<COL>torrey<COL>tolton<EOL><COL>lisa<COL>tolton<EOL>"
    end
  end
end