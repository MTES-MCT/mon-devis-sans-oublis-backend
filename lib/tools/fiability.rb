# frozen_string_literal: true

require "diff/lcs"

# Tools for Fiability
class Fiability
  def self.count_differences(array1, array2)
    changes = Diff::LCS.sdiff(array1, array2)
    changes.count { |change| change.action != "=" }
  end
end
