# frozen_string_literal: true

require "kdl"

module Alibi
  class AlibiFile
    class Parser
      NODES = { files: "the glob of the files to check", pattern: "a regexp" }.freeze
      private_constant(:NODES)

      def initialize(source)
        text = source.dup.force_encoding(Encoding::UTF_8)
        raise(Error, "the alibi file isn't UTF-8 text") unless text.valid_encoding?

        # Without a version, the kdl gem reads a document it can't parse as
        # KDL 2 as KDL 1. Without parse_types: false, it turns an annotated
        # value into an object of the annotation's type.
        @nodes = KDL.parse(text, version: 2, parse_types: false).nodes.map { |node| Node.new(node) }
      rescue KDL::Error => e
        raise(Error, e.message)
      end

      def alibi_file
        @nodes.each { |node| node.known(NODES) }
        NODES.each_key { |name| once(name) }
        AlibiFile.new(glob: Glob.new(string(:files)), pattern: Pattern.new(string(:pattern)))
      end

      private def once(name)
        case @nodes.count { |node| node.named?(name) }
        when 0 then raise(Error, "no `#{name}` node: add one, with #{NODES[name]}")
        when 1 then nil
        else raise(Error, "more than one `#{name}` node: keep one")
        end
      end

      private def string(name)
        strings = @nodes.filter_map { |node| node.string_if_named(name) }
        strings.first
      end
    end
  end
end
