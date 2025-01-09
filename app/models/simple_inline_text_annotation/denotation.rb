class SimpleInlineTextAnnotation
  class Denotation
    attr_reader :begin_pos, :end_pos, :obj

    def initialize(begin_pos, end_pos, obj)
      @begin_pos = begin_pos
      @end_pos = end_pos
      @obj = obj
    end

    def span
      { begin: @begin_pos, end: @end_pos }
    end

    def to_h
      { span: span, obj: @obj }
    end

    def nested_within?(other)
      other.begin_pos <= @begin_pos && @end_pos <= other.end_pos
    end

    def position_negative?
      @begin_pos < 0 || @end_pos < 0
    end

    def position_invalid?
      @begin_pos > @end_pos
    end

    def boundary_crossing?(other)
      starts_inside_other = @begin_pos > other.begin_pos && @begin_pos < other.end_pos
      ends_inside_other = @end_pos > other.begin_pos && @end_pos < other.end_pos

      starts_inside_other || ends_inside_other
    end
  end
end
