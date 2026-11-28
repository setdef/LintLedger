# frozen_string_literal: true

module Alibi
  class AlibiFile
    class Node
      def initialize(node)
        @node = node
        freeze
      end

      def named?(name)
        @node.name == name.name
      end

      def known(names)
        name = @node.name
        raise(Error, "an `alibi` node: this version of Alibi doesn't read alibis yet") if name == "alibi"
        return if names.key?(name.to_sym)

        raise(Error, "unknown node `#{name}`: an alibi file has only `files` and `pattern`")
      end

      def string_if_named(name)
        string if named?(name)
      end

      private def string
        arguments = @node.arguments
        argument = arguments.first
        return argument.value if argument.is_a?(KDL::Value::String) && arguments.size == 1 && plain?(argument)

        raise(Error, "give the `#{@node.name}` node one string argument and nothing else")
      end

      private def plain?(argument)
        @node.properties.empty? && @node.children.empty? && [@node.type, argument.type].none?
      end
    end
  end
end
