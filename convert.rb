file = ARGV.shift.chomp
ofile = File.basename(file, '.rb') + '_spec.rb'

map = {
  /require 'test-unit'/ => "require 'rspec'",
  /class TC(.*)\< Test::Unit::TestCase/ => 'describe \1do',
  /def setup/ => 'before do',
  /test(.*)do/ => 'example\1do',
  /assert_kind_of\((.*),(.*)\)/m => 'expect(\2).to be_kind_of(\1)',
  /assert_respond_to\((.*),\s+(.*)\)/m => 'expect(\1).to respond_to(\2)',
  /assert_raise\((.*?)\){(.*?)}/m => 'expect{\2}.to raise_error(\1)',
  /assert_nothing_raised{(.*?)}/m => 'expect{\1}.not_to raise_error',
  /assert_true\((.*)\)/m => 'expect(\1).to be_true',
  /assert_false\((.*)\)/m => 'expect(\1).to be_false',
}

begin
  fh = File.open(ofile, 'w')

  IO.foreach(file) do |line|
    match_found = false

    map.each do |original, replacement|
      if original.match(line)
        new_line = line.gsub(original, replacement)
        fh.puts new_line
        match_found = true
      end
    end

    fh.puts line unless match_found
  end
ensure
  fh.close
end
