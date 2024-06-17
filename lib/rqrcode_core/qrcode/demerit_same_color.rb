module RQRCodeCore
  class DemeritSameColor
    def initialize(modules, demerit_points)
      @modules = modules
      @demerit_points = demerit_points
    end

    def points
      return 0 if modules.size < 3

      first = row_points([], modules[0], modules[1])
      middle = modules.each_cons(3).sum do |above, current, below|
        row_points(above, current, below)
      end
      last = row_points(modules[-2], modules[-1], [])

      first + middle + last
    end

    private

    attr_reader :modules, :demerit_points

    DEMERIT_THRESHOLD = 5

    def row_points(above, current, below)
      current.each_with_index.sum do |module_dark, i|
        same_count = same_neighbours(above, current, below, i, module_dark)

        next 0 unless same_count > DEMERIT_THRESHOLD

        (demerit_points + same_count - DEMERIT_THRESHOLD)
      end
    end

    def same_neighbours(above, current, below, x, dark)
      [
        at(above, x - 1), at(above, x), at(above, x + 1),
        at(current, x - 1), at(current, x + 1),
        at(below, x - 1), at(below, x), at(below, x + 1)
      ].select { _1 == dark }.count
    end

    def at(row, index)
      return nil if index < 0

      row[index]
    end
  end

  private_constant :DemeritSameColor
end
