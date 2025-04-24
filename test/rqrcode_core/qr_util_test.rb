require "test_helper"

module RQRCodeCore
  class QRUtilTest < Minitest::Test
    def test_demerit_points_4_dark_ratio
      # Test with all white modules (ratio = 0)
      # Expected: (100 * 0 - 50).abs / 5 * 10 = 10 * 10 = 100
      modules = Array.new(4) { Array.new(4, false) }
      assert_equal 100, QRUtil.demerit_points_4_dark_ratio(modules)

      # Test with all black modules (ratio = 1)
      # Expected: (100 * 1 - 50).abs / 5 * 10 = 50 / 5 * 10 = 10 * 10 = 100
      modules = Array.new(4) { Array.new(4, true) }
      assert_equal 100, QRUtil.demerit_points_4_dark_ratio(modules)

      # Test with half black, half white modules (ratio = 0.5)
      # Expected: (100 * 0.5 - 50).abs / 5 * 10 = 0 / 5 * 10 = 0
      modules = [
        [true, true, false, false],
        [true, true, false, false],
        [false, false, true, true],
        [false, false, true, true]
      ]
      assert_equal 0, QRUtil.demerit_points_4_dark_ratio(modules)

      # Test with 25% black modules (ratio = 0.25)
      # Expected: (100 * 0.25 - 50).abs / 5 * 10 = 25 / 5 * 10 = 5 * 10 = 50
      modules = [
        [true, false, false, false],
        [false, true, false, false],
        [false, false, true, false],
        [false, false, false, true]
      ]
      assert_equal 50, QRUtil.demerit_points_4_dark_ratio(modules)

      # Test with 75% black modules (ratio = 0.75)
      # Expected: (100 * 0.75 - 50).abs / 5 * 10 = 25 / 5 * 10 = 5 * 10 = 50
      modules = [
        [true, true, true, true],
        [true, true, true, false],
        [true, true, false, true],
        [true, false, false, true]
      ]
      assert_equal 50, QRUtil.demerit_points_4_dark_ratio(modules)

      # Test with different sized modules (3x3)
      # 3 black out of 9 = 1/3 ratio = 0.33...
      # Expected: (100 * (3/9) - 50).abs / 5 * 10 ≈ 16.67 * 10 = 166.7
      modules = [
        [true, false, false],
        [false, true, false],
        [false, false, true]
      ]
      expected = ((100 * (3.0 / 9) - 50).abs / 5) * 10
      assert_in_delta expected, QRUtil.demerit_points_4_dark_ratio(modules), 0.01
    end

    def test_demerit_points_4_dark_ratio_edge_cases
      # Test with empty modules
      # This shouldn't happen in real QR codes, but let's be safe
      modules = []
      assert QRUtil.demerit_points_4_dark_ratio(modules).nan?

      # Test with 1x1 module
      # All white
      modules = [[false]]
      assert_equal 100, QRUtil.demerit_points_4_dark_ratio(modules)

      # All black
      modules = [[true]]
      assert_equal 100, QRUtil.demerit_points_4_dark_ratio(modules)
    end

    def test_demerit_points_4_dark_ratio_formula
      # Test the formula directly for a specific case
      # For a 5x5 module with 13 dark cells:
      # ratio = 13/25 = 0.52
      # ratio_delta = (100 * 0.52 - 50).abs / 5 = 2/5 = 0.4
      # demerit points = 0.4 * 10 = 4
      modules = [
        [true, true, true, false, false],
        [true, true, true, false, false],
        [true, true, true, false, true],
        [true, true, false, false, false],
        [true, false, false, false, false]
      ]

      # Count dark modules
      dark_count = modules.flatten.count(true)
      assert_equal 13, dark_count

      # Calculate ratio
      ratio = dark_count.to_f / (5 * 5)
      assert_in_delta 0.52, ratio, 0.001

      # Calculate ratio_delta
      ratio_delta = (100 * ratio - 50).abs / 5
      assert_in_delta 0.4, ratio_delta, 0.001

      # Calculate demerit points
      demerit_points = ratio_delta * 10
      assert_in_delta 4, demerit_points, 0.001

      # Check that our method gives the same result
      assert_in_delta 4, QRUtil.demerit_points_4_dark_ratio(modules), 0.001
    end
  end
end
