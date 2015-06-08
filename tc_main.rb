# File:  tc_simple_number.rb

require_relative "main"
require "test/unit"

class TestMain < Test::Unit::TestCase

  def test_city
    assert_equal(4, SimpleNumber.new(2).add(2) )
    assert_equal(6, SimpleNumber.new(2).multiply(3) )
  end

end