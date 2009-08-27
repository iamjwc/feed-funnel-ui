class String
  def dehtmlify
    self.gsub(/&gt;/, ">").gsub(/&lt;/, "<").gsub(/<[^>]*>/m, "").gsub(/\W+/, " ").gsub(/&[a-z]{0,4};/i, "")
  end

  def urlify
    self.gsub(/_+/, "-").strip.gsub(/[^\w]+/, "-").gsub(/^[^\w]*|[^\w]*$/, "")
  end
end

class Array
  alias :head :first

  def tail
    self[1..-1]
  end
end

