# DelimitedFile.gemspec
require 'rubygems'
spec = Gem::Specification.new do |spec|
  spec.name = 'delimited_file'
  spec.summary = 'Delimited text file parser.'
  spec.description = %{The Goal of the library is to build a fast and minimal file parser.
    Defaults to the file being <COL> delimited between fields with <EOL> between rows.
    Files must have a header row for this to work.
    Carriage returns will be left in place to preserve the original formatting as much as possible.
  }
  spec.author = 'Doug Tolton'
  spec.email = 'delimited-file.closure@recursor.net'
  spec.test_files = Dir['test/*']
  spec.has_rdoc = true
  spec.files = Dir['lib/*.rb'] + spec.test_files
  spec.version = '0.4.0'
end