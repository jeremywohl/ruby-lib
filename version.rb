# Processes version strings for comparison and blocking.
#
#   Version.new('1.2.3') > '1.2'  # -> true
#   Version.new('1').to_s         # -> '1.0.0'
#
#   version = Version.new('1.2.3')
#
#   version.greater_or_equal('1.1') do
#     ...
#   end
#
#   version.between('1.1', '1.3') do
#     ...
#   end
#
# Grabs ideas from RubyGems' Version class
#   http://rubygems.rubyforge.org/svn/trunk/lib/rubygems/version.rb
# and Rubicon's LanguageVersion
#   http://rubytests.rubyforge.org/svn/trunk/old/rubicon/rubicon.rb
#
# Jeremy Wohl
#   http://igmus.org/
#   http://github.com/jeremywohl/ruby-bits
#
# public domain -- patches / pull requests welcome
#

class Version
  
  # for to_s presentation
  SEPARATOR    = '.'
  MIN_ELEMENTS = 3
  
  include Comparable
  
  attr_reader :ints
  
  # Accepts String, Number or Version, where strings contain digits with any separators,
  # e.g. '1.1', '1_0', '1 4', '1 dot 23 dot 3'. Cannot be nil or empty. Version's are immutable.
  def initialize(version)
    @ints = version.to_s.scan(/\d+/).map { |s| s.to_i }
    @ints.pop while @ints.last == 0
    
    raise ArgumentError, "Malformed version number string #{version}" unless @ints.any?
  end

  def to_s
    ( 1 .. [MIN_ELEMENTS, @ints.size].max ).to_a.map { |i| ( @ints[i - 1] || 0 ).to_s }.join(SEPARATOR)
  end
  
  # See Comparable.  Note, versions '1', '1.0' and '1.0.0' are equivalent.
  def <=>(_other)
    other = self.class === _other ? _other : Version.new(_other)
    @ints <=> other.ints
  end
  
  def between(min, max)
    yield if self.between?(min, max)
  end

  def greater_than(version)
    yield if self > version
  end

  def greater_or_equal(version)
    yield if self >= version
  end

  def less_than(version)
    yield if self < version
  end

  def less_or_equal(version)
    yield if self <= version
  end

end

if __FILE__ == $0
  
  require 'test/unit'
  require 'test/unit/ui/console/testrunner'
  
  class VersionTest < Test::Unit::TestCase
    
    def test_initialization
      assert_equal '1.1.0', Version.new('1.1').to_s
      assert_equal '1.1.0', Version.new('1_1').to_s
      assert_equal '1.1.0', Version.new('1+1').to_s
      assert_equal '1.1.0', Version.new('1 1').to_s
      assert_equal '1.1.0', Version.new('1 . 1').to_s
      assert_equal '1.1.0', Version.new('1 dot 1').to_s
      
      assert_raise ArgumentError do
        Version.new(nil)
      end
      
      assert_raise ArgumentError do
        Version.new('')
      end
      
      assert_raise ArgumentError do
        Version.new('fred')
      end
    end
    
    def test_to_s
      assert_equal '1.1.1', Version.new('1.1.1').to_s
      assert_equal '1.0.0', Version.new('1.0').to_s
      assert_equal '1.0.0', Version.new('1').to_s
      
      assert_equal '1.1.1.1', Version.new('1.1.1.1').to_s  # longer than minimum
    end
    
    def test_comparison
      assert Version.new('1.1.1') > '1'
      assert Version.new('1.1') > '1'
      assert Version.new('1') == '1'
      
      assert Version.new('1.1.1') > Version.new('1')
      assert Version.new('1.1') > Version.new('1')
      assert Version.new('1') == Version.new('1')
      
      assert Version.new('1.10.1') > Version.new('1.9.1')  # would fail a lexicographic comparison
    end
    
    def test_between
      t = 0
      
      assert_equal 0, t
      
      Version.new('1.1.1').between('1', '2') do
        t = 1
      end
      
      assert_equal 1, t, 'between block failed to run'
    end
    
    def test_greater_or_equal
      t = 0
      
      assert_equal 0, t
      
      Version.new('1.1').greater_or_equal('1.1') do
        t = 1
      end
      
      assert_equal 1, t, 'greater_than block failed to run'
    end

    def test_less_than
      t = 0
      
      assert_equal 0, t
      
      Version.new('1_0').less_than('1.1') do
        t = 1
      end
      
      assert_equal 1, t, 'less_than block failed to run'
    end
    
  end
  
  Test::Unit::UI::Console::TestRunner.run(VersionTest)
  
end
