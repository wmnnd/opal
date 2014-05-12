# require 'opal'
require 'sourcemap'

module Opal
  class SourceMap
    attr_reader :fragments
    attr_reader :file

    def initialize(fragments, file)
      @fragments = fragments
      @file = file
    end

    def map
      # @mappings = SourceMap::Map.new([
      #   SourceMap::Mapping.new('a.js', SourceMap::Offset.new(0, 0), SourceMap::Offset.new(0, 0)),
      #   SourceMap::Mapping.new('b.js', SourceMap::Offset.new(1, 0), SourceMap::Offset.new(20, 0)),
      #   SourceMap::Mapping.new('c.js', SourceMap::Offset.new(2, 0), SourceMap::Offset.new(30, 0))
      # ])

      @map ||= begin
        line, column = 1, 0

        mappings = []
        @fragments.each do |fragment|
          if source_line = fragment.line
            mappings << ::SourceMap::Mapping.new(file,
              ::SourceMap::Offset.new(line, column),
              ::SourceMap::Offset.new(source_line, fragment.column)
            )
            # map.add_mapping(
            #   :generated_line => line,
            #   :generated_col  => column,
            #   :source_line    => source_line,
            #   :source_col     => fragment.column,
            #   :source         => file
            # )
          end

          new_lines = fragment.code.count "\n"
          line += new_lines

          if new_lines > 0
            column = fragment.code.size - (fragment.code.rindex("\n") + 1)
          else
            column += fragment.code.size
          end
        end

        ::SourceMap::Map.new(mappings)
      end
    end

    def + other
      to_source_map + other.to_source_map
    end

    def to_source_map
      map
    end

    def as_json
      map.as_json
    end

    def to_s
      map.to_s
    end

    def magic_comment map_path
      "\n//# sourceMappingURL=file://#{map_path}"
    end
  end
end
