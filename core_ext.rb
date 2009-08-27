class String
  def strip_html
    self.gsub(/&gt;/, ">").gsub(/&lt;/, "<").gsub(/<[^>]*>/m, "").gsub(/\W+/, " ").gsub(/&[a-z]{0,4};/i, "")
  end
end

class Array
  alias :head :first

  def tail
    self[1..-1]
  end
end

